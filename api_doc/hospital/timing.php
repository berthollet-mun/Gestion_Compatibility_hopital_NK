<?php
// Test de timing étape par étape — accès: http://localhost/hospital/timing.php
header('Content-Type: application/json; charset=UTF-8');

$steps = [];
$start = microtime(true);

function mark($label) {
    global $steps, $start;
    $steps[] = $label . ': ' . round((microtime(true) - $start) * 1000) . 'ms';
}

mark('START');

require_once __DIR__ . '/api/config/Config.php';
mark('Config loaded');

require_once __DIR__ . '/api/config/Database.php';
mark('Database class loaded');

require_once __DIR__ . '/api/helpers/PasswordHelper.php';
mark('PasswordHelper loaded');

$db = Database::getInstance();
mark('DB connected');

$stmt = $db->prepare('SELECT u.*, r.nom AS role_nom, r.niveau AS role_niveau FROM users u JOIN roles r ON r.id = u.role_id WHERE u.email = ? AND u.deleted_at IS NULL LIMIT 1');
$stmt->execute(['admin@hopital-nk.cd']);
$user = $stmt->fetch();
mark('User found: ' . ($user ? 'YES' : 'NO'));

if ($user) {
    $ok = PasswordHelper::verify('Admin@2024', $user['password_hash']);
    mark('Password verify: ' . ($ok ? 'OK' : 'FAIL') . ' (hash cost: ' . substr($user['password_hash'], 0, 7) . ')');

    // Test permissions query
    $stmt2 = $db->prepare('SELECT CONCAT(p.module, \'.\', p.action) AS permission FROM role_permissions rp JOIN permissions p ON p.id = rp.permission_id WHERE rp.role_id = ?');
    $stmt2->execute([$user['role_id']]);
    $perms = $stmt2->fetchAll();
    mark('Permissions loaded: ' . count($perms) . ' perms');
}

mark('DONE');

echo json_encode(['timing' => $steps, 'total_ms' => round((microtime(true) - $start) * 1000)], JSON_PRETTY_PRINT);
