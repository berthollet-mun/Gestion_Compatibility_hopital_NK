<?php
// api/helpers/JwtHelper.php

require_once __DIR__ . '/../config/Config.php';

class JwtHelper {
    private static string $secret;
    private static int $expiry;

    private static function init(): void {
        self::$secret = Config::get('JWT_SECRET', 'default_secret_change_me');
        self::$expiry = (int) Config::get('JWT_EXPIRY', 3600);
    }

    /**
     * Générer un token JWT
     */
    public static function generate(array $payload): string {
        self::init();

        $header = self::base64UrlEncode(json_encode([
            'alg' => 'HS256',
            'typ' => 'JWT'
        ]));

        $payload['iat'] = time();
        $payload['exp'] = time() + self::$expiry;
        $payload['jti'] = bin2hex(random_bytes(16)); // JWT ID unique

        $payloadEncoded = self::base64UrlEncode(json_encode($payload));

        $signature = self::base64UrlEncode(
            hash_hmac('sha256', "{$header}.{$payloadEncoded}", self::$secret, true)
        );

        return "{$header}.{$payloadEncoded}.{$signature}";
    }

    /**
     * Générer un refresh token
     */
    public static function generateRefresh(int $userId): string {
        self::init();
        $expiry = (int) Config::get('JWT_REFRESH_EXPIRY', 604800);

        $payload = [
            'user_id' => $userId,
            'type'    => 'refresh',
            'iat'     => time(),
            'exp'     => time() + $expiry,
            'jti'     => bin2hex(random_bytes(16)),
        ];

        $header  = self::base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $encoded = self::base64UrlEncode(json_encode($payload));
        $sig     = self::base64UrlEncode(
            hash_hmac('sha256', "{$header}.{$encoded}", self::$secret . '_refresh', true)
        );

        return "{$header}.{$encoded}.{$sig}";
    }

    /**
     * Vérifier et décoder un token JWT
     */
    public static function verify(string $token): array {
        self::init();

        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            throw new InvalidArgumentException('Format de token invalide');
        }

        [$header, $payload, $signature] = $parts;

        // Vérifier la signature
        $expectedSig = self::base64UrlEncode(
            hash_hmac('sha256', "{$header}.{$payload}", self::$secret, true)
        );

        if (!hash_equals($expectedSig, $signature)) {
            throw new RuntimeException('Signature du token invalide');
        }

        $decodedPayload = json_decode(self::base64UrlDecode($payload), true);

        if (!$decodedPayload) {
            throw new RuntimeException('Payload du token invalide');
        }

        // Vérifier l'expiration
        if (isset($decodedPayload['exp']) && $decodedPayload['exp'] < time()) {
            throw new RuntimeException('Token expiré');
        }

        return $decodedPayload;
    }

    /**
     * Extraire le token du header Authorization
     */
    public static function extractFromHeader(): ?string {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION']
                   ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
                   ?? null;

        // Si non trouvé dans $_SERVER, chercher dans les headers Apache
        if (!$authHeader && function_exists('apache_request_headers')) {
            $headers = apache_request_headers();
            // Recherche insensible à la casse
            foreach ($headers as $key => $value) {
                if (strtolower($key) === 'authorization') {
                    $authHeader = $value;
                    break;
                }
            }
        }

        if (!$authHeader) return null;

        if (preg_match('/Bearer\s+(.+)/i', $authHeader, $matches)) {
            return $matches[1];
        }

        return null;
    }

    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', 3 - (3 + strlen($data)) % 4));
    }
}