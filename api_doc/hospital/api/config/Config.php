<?php
// api/config/Config.php

class Config {
    private static array $config = [];

    public static function load(): void {
        $envFile = __DIR__ . '/../.env';
        if (!file_exists($envFile)) {
            throw new RuntimeException('.env file not found');
        }

        $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (str_starts_with(trim($line), '#')) continue;
            if (!str_contains($line, '=')) continue;

            [$key, $value] = explode('=', $line, 2);
            $key   = trim($key);
            $value = trim($value);

            self::$config[$key] = $value;
            $_ENV[$key] = $value;
        }
    }

    public static function get(string $key, mixed $default = null): mixed {
        return self::$config[$key] ?? $_ENV[$key] ?? $default;
    }
}

// Charger automatiquement
Config::load();