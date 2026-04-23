<?php
// api/controllers/AuthController.php

class AuthController {

    private UserModel $userModel;

    public function __construct() {
        $this->userModel = new UserModel();
    }

    /**
     * POST /auth/login
     * Authentifier un utilisateur avec email + mot de passe
     */
    public function login(): void {
        $data = ValidationMiddleware::getJsonBody();

        $validator = ValidationMiddleware::make($data)
            ->required('email', 'Email')
            ->required('password', 'Mot de passe')
            ->email('email');

        if ($validator->fails()) {
            ResponseHelper::error('Données invalides', 422, $validator->getErrors());
        }

        $email    = $data['email'];
        $password = $data['password'];

        // Rechercher l'utilisateur
        $user = $this->userModel->findByEmail($email);

        if (!$user) {
            AuditHelper::log(null, 'LOGIN_FAILED', 'users', null, null, ['email' => $email], 'FAILURE');
            ResponseHelper::error('Identifiants incorrects', 401);
        }

        // Vérifier si le compte est verrouillé
        if (!empty($user['locked_until']) && strtotime($user['locked_until']) > time()) {
            $minutes = ceil((strtotime($user['locked_until']) - time()) / 60);
            ResponseHelper::error(
                "Compte verrouillé. Réessayez dans {$minutes} minute(s)",
                423
            );
        }

        // Vérifier si le compte est actif
        if (empty($user['is_active']) || $user['is_active'] == 0) {
            ResponseHelper::error('Compte désactivé. Contactez l\'administrateur', 403);
        }

        // Vérifier le mot de passe
        if (!PasswordHelper::verify($password, $user['password_hash'])) {
            // Incrémenter les tentatives échouées
            $this->userModel->incrementFailedAttempts($user['id']);

            $maxAttempts = (int) Config::get('MAX_LOGIN_ATTEMPTS', 5);
            $failedAttempts = ($user['failed_attempts'] ?? 0) + 1;

            if ($failedAttempts >= $maxAttempts) {
                $lockoutMinutes = (int) Config::get('LOCKOUT_DURATION', 900) / 60;
                $this->userModel->lockAccount($user['id'], $lockoutMinutes);
            }

            AuditHelper::log($user['id'], 'LOGIN_FAILED', 'users', $user['id'], null, null, 'FAILURE');
            ResponseHelper::error('Identifiants incorrects', 401);
        }

        // Succès — réinitialiser les tentatives
        $this->userModel->resetFailedAttempts($user['id']);
        $this->userModel->updateLastLogin($user['id']);

        // Générer les tokens
        $tokenPayload = [
            'user_id'   => $user['id'],
            'email'     => $user['email'],
            'role_id'   => $user['role_id'],
            'role_nom'  => $user['role_nom'] ?? '',
        ];

        $accessToken  = JwtHelper::generate($tokenPayload);
        $refreshToken = JwtHelper::generateRefresh($user['id']);

        // Charger les permissions
        $userWithPerms = $this->userModel->getWithPermissions($user['id']);

        AuditHelper::log($user['id'], 'LOGIN_SUCCESS', 'users', $user['id']);

        ResponseHelper::success([
            'token'         => $accessToken,
            'refresh_token' => $refreshToken,
            'user'          => $userWithPerms,
        ], 'Connexion réussie');
    }

    /**
     * POST /auth/logout
     */
    public function logout(): void {
        $user = AuthMiddleware::handle();

        AuditHelper::log($user['id'], 'LOGOUT', 'users', $user['id']);

        ResponseHelper::success(null, 'Déconnexion réussie');
    }

    /**
     * POST /auth/refresh
     * Rafraîchir le token d'accès avec un refresh token
     */
    public function refresh(): void {
        $data = ValidationMiddleware::getJsonBody();

        if (empty($data['refresh_token'])) {
            ResponseHelper::error('Refresh token manquant', 400);
        }

        try {
            // Vérifier le refresh token (signature avec _refresh suffix)
            $parts = explode('.', $data['refresh_token']);
            if (count($parts) !== 3) {
                throw new InvalidArgumentException('Format de refresh token invalide');
            }

            [$header, $payload, $signature] = $parts;

            $decodedPayload = json_decode(
                base64_decode(strtr($payload, '-_', '+/') . str_repeat('=', 3 - (3 + strlen($payload)) % 4)),
                true
            );

            if (!$decodedPayload) {
                throw new RuntimeException('Payload invalide');
            }

            if (($decodedPayload['type'] ?? '') !== 'refresh') {
                throw new RuntimeException('Ce n\'est pas un refresh token');
            }

            if (isset($decodedPayload['exp']) && $decodedPayload['exp'] < time()) {
                throw new RuntimeException('Refresh token expiré');
            }

            $userId = $decodedPayload['user_id'] ?? 0;
            $user   = $this->userModel->getWithPermissions($userId);

            if (!$user) {
                ResponseHelper::error('Utilisateur introuvable', 401);
            }

            // Générer un nouveau access token
            $newToken = JwtHelper::generate([
                'user_id'   => $user['id'],
                'email'     => $user['email'],
                'role_id'   => $user['role_id'],
                'role_nom'  => $user['role_nom'] ?? '',
            ]);

            $newRefresh = JwtHelper::generateRefresh($user['id']);

            ResponseHelper::success([
                'token'         => $newToken,
                'refresh_token' => $newRefresh,
                'user'          => $user,
            ], 'Token rafraîchi');

        } catch (Exception $e) {
            ResponseHelper::error('Refresh token invalide : ' . $e->getMessage(), 401);
        }
    }

    /**
     * POST /auth/change-password
     * Changer le mot de passe de l'utilisateur connecté
     */
    public function changePassword(): void {
        $user = AuthMiddleware::handle();
        $data = ValidationMiddleware::getJsonBody();

        $validator = ValidationMiddleware::make($data)
            ->required('current_password', 'Mot de passe actuel')
            ->required('new_password', 'Nouveau mot de passe')
            ->minLength('new_password', 8);

        if ($validator->fails()) {
            ResponseHelper::error('Données invalides', 422, $validator->getErrors());
        }

        // Récupérer le hash actuel
        $db   = Database::getInstance();
        $stmt = $db->prepare("SELECT password_hash FROM users WHERE id = ?");
        $stmt->execute([$user['id']]);
        $currentHash = $stmt->fetchColumn();

        if (!$currentHash || !PasswordHelper::verify($data['current_password'], $currentHash)) {
            ResponseHelper::error('Mot de passe actuel incorrect', 400);
        }

        // Vérifier la robustesse du nouveau mot de passe
        if (!PasswordHelper::isStrong($data['new_password'])) {
            ResponseHelper::error(
                'Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule et un chiffre',
                422
            );
        }

        // Mettre à jour
        $newHash = PasswordHelper::hash($data['new_password']);
        $db->prepare(
            "UPDATE users SET password_hash = ?, must_change_pwd = 0, updated_at = NOW() WHERE id = ?"
        )->execute([$newHash, $user['id']]);

        AuditHelper::log($user['id'], 'PASSWORD_CHANGED', 'users', $user['id']);

        ResponseHelper::success(null, 'Mot de passe modifié avec succès');
    }

    /**
     * GET /auth/me
     * Retourner le profil de l'utilisateur connecté
     */
    public function me(): void {
        $user = AuthMiddleware::handle();

        $profile = $this->userModel->getWithPermissions($user['id']);

        if (!$profile) {
            ResponseHelper::error('Utilisateur introuvable', 404);
        }

        ResponseHelper::success($profile, 'Profil récupéré');
    }
}
