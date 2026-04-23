<?php
// api/helpers/AuditHelper.php

class AuditHelper {
    public static function log(
        ?int $userId,
        string $action,
        ?string $tableCible = null,
        ?int $enregistrementId = null,
        ?array $anciennesValeurs = null,
        ?array $nouvellesValeurs = null,
        string $statut = 'SUCCESS'
    ): void {
        try {
            $db   = Database::getInstance();
            $sql  = "INSERT INTO audit_logs
                        (user_id, action, table_cible, enregistrement_id,
                         anciennes_valeurs, nouvelles_valeurs, ip_address, statut)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

            $stmt = $db->prepare($sql);
            $stmt->execute([
                $userId,
                $action,
                $tableCible,
                $enregistrementId,
                $anciennesValeurs ? json_encode($anciennesValeurs, JSON_UNESCAPED_UNICODE) : null,
                $nouvellesValeurs ? json_encode($nouvellesValeurs, JSON_UNESCAPED_UNICODE) : null,
                self::getClientIp(),
                $statut
            ]);
        } catch (Exception $e) {
            // Ne pas bloquer l'app si l'audit échoue
            error_log("AuditHelper error: " . $e->getMessage());
        }
    }

    private static function getClientIp(): string {
        return $_SERVER['HTTP_X_FORWARDED_FOR']
            ?? $_SERVER['REMOTE_ADDR']
            ?? '0.0.0.0';
    }
}