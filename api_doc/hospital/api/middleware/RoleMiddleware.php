<?php
// api/middleware/RoleMiddleware.php

require_once __DIR__ . '/../helpers/ResponseHelper.php';

class RoleMiddleware {

    /**
     * Vérifier qu'un utilisateur a la permission requise
     * Format permission : 'module.action' ex: 'comptabilite.create'
     */
    public static function checkPermission(array $user, string $permission): void {
        if (!in_array($permission, $user['permissions'])) {
            ResponseHelper::error(
                "Accès refusé : permission '{$permission}' requise",
                403
            );
        }
    }

    /**
     * Vérifier qu'un utilisateur a l'un des rôles requis
     */
    public static function checkRole(array $user, array $roles): void {
        if (!in_array($user['role_nom'], $roles)) {
            ResponseHelper::error(
                'Accès refusé : rôle insuffisant',
                403
            );
        }
    }

    /**
     * Vérifier un niveau minimum
     */
    public static function checkLevel(array $user, int $minLevel): void {
        if ((int)$user['role_niveau'] < $minLevel) {
            ResponseHelper::error(
                'Accès refusé : niveau de privilège insuffisant',
                403
            );
        }
    }

    /**
     * Vérifier plusieurs permissions (toutes requises)
     */
    public static function checkAllPermissions(array $user, array $permissions): void {
        foreach ($permissions as $perm) {
            self::checkPermission($user, $perm);
        }
    }

    /**
     * Vérifier au moins une permission parmi la liste
     */
    public static function checkAnyPermission(array $user, array $permissions): void {
        foreach ($permissions as $perm) {
            if (in_array($perm, $user['permissions'])) return;
        }
        ResponseHelper::error('Accès refusé : aucune permission suffisante', 403);
    }
}