<?php
// api/middleware/AuthMiddleware.php

require_once __DIR__ . '/../helpers/JwtHelper.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../config/Database.php';

class AuthMiddleware {
    private static ?array $currentUser = null;

    /**
     * Vérifier le JWT et charger l'utilisateur
     */
    public static function handle(): array {
        $token = JwtHelper::extractFromHeader();

        // Debug logging
        if (Config::get('APP_DEBUG') === 'true') {
            $logFile = __DIR__ . '/../debug_auth.log';
            $method = $_SERVER['REQUEST_METHOD'] ?? 'UNKNOWN';
            $uri = $_SERVER['REQUEST_URI'] ?? 'UNKNOWN';
            $hasToken = $token ? 'YES (' . substr($token, 0, 10) . '...)' : 'NO';
            $allHeaders = function_exists('apache_request_headers') ? json_encode(apache_request_headers()) : 'N/A';
            
            $logMsg = sprintf(
                "[%s] %s %s | Token: %s | Headers: %s\n",
                date('Y-m-d H:i:s'),
                $method,
                $uri,
                $hasToken,
                $allHeaders
            );
            file_put_contents($logFile, $logMsg, FILE_APPEND);
        }

        if (!$token) {
            ResponseHelper::error('Token d\'authentification manquant', 401);
        }

        try {
            $payload = JwtHelper::verify($token);
        } catch (RuntimeException $e) {
            ResponseHelper::error($e->getMessage(), 401);
        }

        // Charger l'utilisateur depuis la BDD
        $user = self::loadUser($payload['user_id'] ?? 0);

        if (!$user) {
            ResponseHelper::error('Utilisateur introuvable ou inactif', 401);
        }

        self::$currentUser = $user;
        return $user;
    }

    /**
     * Charger l'utilisateur avec ses permissions
     */
    private static function loadUser(int $userId): ?array {
        $db  = Database::getInstance();
        $sql = "SELECT u.id, u.matricule, u.nom, u.prenom, u.email,
                       u.role_id, r.nom AS role_nom, r.niveau AS role_niveau,
                       u.service_id, u.is_active, u.must_change_pwd
                FROM users u
                JOIN roles r ON r.id = u.role_id
                WHERE u.id = ?
                  AND u.is_active = 1
                  AND u.deleted_at IS NULL";

        $stmt = $db->prepare($sql);
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) return null;

        // Charger les permissions
        $sqlPerms = "SELECT CONCAT(p.module, '.', p.action) AS permission
                     FROM role_permissions rp
                     JOIN permissions p ON p.id = rp.permission_id
                     WHERE rp.role_id = ?";

        $stmtP = $db->prepare($sqlPerms);
        $stmtP->execute([$user['role_id']]);
        $user['permissions'] = array_column($stmtP->fetchAll(), 'permission');

        return $user;
    }

    public static function getCurrentUser(): ?array {
        return self::$currentUser;
    }
}