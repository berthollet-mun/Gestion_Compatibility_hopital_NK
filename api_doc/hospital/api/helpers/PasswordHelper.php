<?php
// api/helpers/PasswordHelper.php

class PasswordHelper {
    private static int $cost = 10;

    public static function hash(string $password): string {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => self::$cost]);
    }

    public static function verify(string $password, string $hash): bool {
        return password_verify($password, $hash);
    }

    public static function needsRehash(string $hash): bool {
        return password_needs_rehash($hash, PASSWORD_BCRYPT, ['cost' => self::$cost]);
    }

    public static function isStrong(string $password): bool {
        // Min 8 chars, 1 majuscule, 1 minuscule, 1 chiffre
        return strlen($password) >= 8
            && preg_match('/[A-Z]/', $password)
            && preg_match('/[a-z]/', $password)
            && preg_match('/[0-9]/', $password);
    }
}