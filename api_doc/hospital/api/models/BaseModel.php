<?php
// api/models/BaseModel.php

abstract class BaseModel {
    protected MySQLiConnection $db;
    protected string $table;
    protected string $primaryKey = 'id';

    public function __construct() {
        $this->db = Database::getInstance();
    }

    /**
     * Trouver un enregistrement par ID
     */
    public function findById(int $id): ?array {
        $sql  = "SELECT * FROM {$this->table} WHERE {$this->primaryKey} = ? LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        $result = $stmt->fetch();
        return $result ?: null;
    }

    /**
     * Trouver tous les enregistrements
     */
    public function findAll(array $conditions = [], int $limit = 100, int $offset = 0): array {
        $sql    = "SELECT * FROM {$this->table}";
        $params = [];

        if (!empty($conditions)) {
            $where  = array_map(fn($k) => "`{$k}` = ?", array_keys($conditions));
            $sql   .= " WHERE " . implode(' AND ', $where);
            $params = array_values($conditions);
        }

        $sql .= " LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    /**
     * Compter les enregistrements
     */
    public function count(array $conditions = []): int {
        $sql    = "SELECT COUNT(*) FROM {$this->table}";
        $params = [];

        if (!empty($conditions)) {
            $where  = array_map(fn($k) => "`{$k}` = ?", array_keys($conditions));
            $sql   .= " WHERE " . implode(' AND ', $where);
            $params = array_values($conditions);
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return (int) $stmt->fetchColumn();
    }

    /**
     * Créer un enregistrement
     */
    public function create(array $data): int {
        $columns  = implode(', ', array_map(fn($k) => "`{$k}`", array_keys($data)));
        $placeholders = implode(', ', array_fill(0, count($data), '?'));
        $sql      = "INSERT INTO {$this->table} ({$columns}) VALUES ({$placeholders})";

        $stmt = $this->db->prepare($sql);
        $stmt->execute(array_values($data));
        return (int) $this->db->lastInsertId();
    }

    /**
     * Mettre à jour un enregistrement
     */
    public function update(int $id, array $data): bool {
        $set    = implode(', ', array_map(fn($k) => "`{$k}` = ?", array_keys($data)));
        $sql    = "UPDATE {$this->table} SET {$set} WHERE {$this->primaryKey} = ?";
        $params = [...array_values($data), $id];

        $stmt = $this->db->prepare($sql);
        return $stmt->execute($params);
    }

    /**
     * Supprimer (soft delete si deleted_at existe, sinon hard delete)
     */
    public function delete(int $id): bool {
        // Vérifier si la table a un champ deleted_at (soft delete)
        $checkSql  = "SHOW COLUMNS FROM {$this->table} LIKE 'deleted_at'";
        $checkStmt = $this->db->prepare($checkSql);
        $checkStmt->execute();

        if ($checkStmt->rowCount() > 0) {
            $sql = "UPDATE {$this->table} SET deleted_at = NOW() WHERE {$this->primaryKey} = ?";
        } else {
            $sql = "DELETE FROM {$this->table} WHERE {$this->primaryKey} = ?";
        }

        $stmt = $this->db->prepare($sql);
        return $stmt->execute([$id]);
    }

    /**
     * Exécuter une requête personnalisée
     */
    protected function query(string $sql, array $params = []): array {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    /**
     * Exécuter sans résultat
     */
    protected function execute(string $sql, array $params = []): bool {
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($params);
    }
}