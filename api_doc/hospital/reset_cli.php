<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'hopital_compta_local');
if ($conn->connect_error) {
    echo "ERREUR connexion: " . $conn->connect_error . "\n";
    exit(1);
}

$password = 'Admin@2024';
$hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);

echo "Hash généré: " . substr($hash, 0, 12) . "...\n";
echo "Longueur: " . strlen($hash) . "\n";
echo "Vérification: " . (password_verify($password, $hash) ? "OK" : "FAIL") . "\n";

$stmt = $conn->prepare("UPDATE users SET password_hash = ?, must_change_pwd = 0, failed_attempts = 0, locked_until = NULL");
$stmt->bind_param('s', $hash);
$stmt->execute();
echo "Utilisateurs mis à jour: " . $stmt->affected_rows . "\n";
$stmt->close();

$result = $conn->query("SELECT id, email, LEFT(password_hash,7) as cost_prefix FROM users");
while ($row = $result->fetch_assoc()) {
    echo "  - [{$row['id']}] {$row['email']} => {$row['cost_prefix']}...\n";
}
$conn->close();
echo "DONE\n";
