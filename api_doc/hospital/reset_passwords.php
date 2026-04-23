<?php
// Script temporaire pour réinitialiser les mots de passe
// Accès : http://localhost/hospital/reset_passwords.php

$host   = '127.0.0.1';
$user   = 'root';
$pass   = '';
$dbname = 'hopital_compta_local';

$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    die("Connexion échouée: " . $conn->connect_error);
}

// Mot de passe pour tous les comptes de test
$password   = 'Admin@2024';
$hash       = password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);

// Mise à jour des 2 utilisateurs
$stmt = $conn->prepare(
    "UPDATE users SET password_hash = ?, must_change_pwd = 0, failed_attempts = 0, locked_until = NULL"
);
$stmt->bind_param('s', $hash);
$stmt->execute();

$affected = $stmt->affected_rows;
$stmt->close();

// Vérification
$result = $conn->query("SELECT id, email, LEFT(password_hash,7) as cost FROM users");
echo "<h2>✅ Réinitialisation réussie ($affected lignes)</h2>";
echo "<p>Nouveau mot de passe : <strong>Admin@2024</strong></p>";
echo "<table border='1' cellpadding='8'><tr><th>ID</th><th>Email</th><th>Coût bcrypt</th><th>Vérif</th></tr>";
while ($row = $result->fetch_assoc()) {
    $verif = password_verify($password, $hash) ? '✅' : '❌';
    echo "<tr><td>{$row['id']}</td><td>{$row['email']}</td><td>{$row['cost']}</td><td>$verif</td></tr>";
}
echo "</table>";
echo "<p style='color:red'>⚠️ Supprimez ce fichier après usage !</p>";

$conn->close();
