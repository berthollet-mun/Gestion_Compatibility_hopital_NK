<?php
// Test complet du login
require_once __DIR__ . '/api/config/Config.php';
require_once __DIR__ . '/api/config/Database.php';
require_once __DIR__ . '/api/helpers/PasswordHelper.php';

echo "=== TEST LOGIN DIRECT ===\n";

try {
    $db = Database::getInstance();
    echo "DB connectée ✅\n";

    $stmt = $db->prepare('SELECT id, email, password_hash, is_active, failed_attempts, locked_until FROM users WHERE email = ?');
    $stmt->execute(['admin@hopital-nk.cd']);
    $user = $stmt->fetch();

    if (!$user) {
        echo "❌ Utilisateur non trouvé\n";
        exit(1);
    }

    echo "Utilisateur trouvé ✅\n";
    echo "  email      : " . $user['email'] . "\n";
    echo "  is_active  : " . $user['is_active'] . "\n";
    echo "  failed_att : " . $user['failed_attempts'] . "\n";
    echo "  locked     : " . ($user['locked_until'] ?? 'NULL') . "\n";
    echo "  hash_cost  : " . substr($user['password_hash'], 0, 7) . "\n";

    $pwdOk = PasswordHelper::verify('Admin@2024', $user['password_hash']);
    echo "Vérif mot de passe 'Admin@2024': " . ($pwdOk ? "✅ OK" : "❌ FAIL") . "\n";

    if (!$pwdOk) {
        // Générer un nouveau hash et l'afficher
        $newHash = PasswordHelper::hash('Admin@2024');
        echo "Nouveau hash généré: " . $newHash . "\n";
        // Mettre à jour directement
        $upd = $db->prepare('UPDATE users SET password_hash = ?, must_change_pwd = 0, failed_attempts = 0 WHERE email = ?');
        $upd->execute([$newHash, 'admin@hopital-nk.cd']);
        echo "Hash mis à jour ✅\n";

        // Re-vérifier
        $stmt2 = $db->prepare('SELECT password_hash FROM users WHERE email = ?');
        $stmt2->execute(['admin@hopital-nk.cd']);
        $u2 = $stmt2->fetch();
        echo "Re-vérif: " . (PasswordHelper::verify('Admin@2024', $u2['password_hash']) ? "✅ OK" : "❌ FAIL") . "\n";
    }

} catch (Throwable $e) {
    echo "EXCEPTION: " . $e->getMessage() . "\n";
}
