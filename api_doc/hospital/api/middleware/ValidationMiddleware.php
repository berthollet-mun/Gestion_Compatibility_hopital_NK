<?php
// api/middleware/ValidationMiddleware.php

class ValidationMiddleware {

    private array $data;
    private array $errors = [];

    public function __construct(array $data) {
        $this->data = $data;
    }

    public static function make(array $data): self {
        return new self($data);
    }

    public function required(string $field, string $label = ''): self {
        $label = $label ?: $field;
        if (!isset($this->data[$field]) || trim((string)$this->data[$field]) === '') {
            $this->errors[$field] = "Le champ '{$label}' est obligatoire";
        }
        return $this;
    }

    public function email(string $field): self {
        if (isset($this->data[$field]) && !filter_var($this->data[$field], FILTER_VALIDATE_EMAIL)) {
            $this->errors[$field] = "Format email invalide";
        }
        return $this;
    }

    public function minLength(string $field, int $min): self {
        if (isset($this->data[$field]) && strlen($this->data[$field]) < $min) {
            $this->errors[$field] = "Minimum {$min} caractères requis";
        }
        return $this;
    }

    public function maxLength(string $field, int $max): self {
        if (isset($this->data[$field]) && strlen($this->data[$field]) > $max) {
            $this->errors[$field] = "Maximum {$max} caractères autorisés";
        }
        return $this;
    }

    public function numeric(string $field): self {
        if (isset($this->data[$field]) && !is_numeric($this->data[$field])) {
            $this->errors[$field] = "Doit être un nombre";
        }
        return $this;
    }

    public function positive(string $field): self {
        if (isset($this->data[$field]) && (float)$this->data[$field] <= 0) {
            $this->errors[$field] = "Doit être un nombre positif";
        }
        return $this;
    }

    public function date(string $field): self {
        if (isset($this->data[$field])) {
            $d = DateTime::createFromFormat('Y-m-d', $this->data[$field]);
            if (!$d || $d->format('Y-m-d') !== $this->data[$field]) {
                $this->errors[$field] = "Format de date invalide (YYYY-MM-DD)";
            }
        }
        return $this;
    }

    public function inArray(string $field, array $values): self {
        if (isset($this->data[$field]) && !in_array($this->data[$field], $values)) {
            $this->errors[$field] = "Valeur non autorisée. Valeurs permises : " . implode(', ', $values);
        }
        return $this;
    }

    public function unique(string $field, string $table, string $column, ?int $excludeId = null): self {
        if (isset($this->data[$field])) {
            $db  = Database::getInstance();
            $sql = "SELECT COUNT(*) FROM {$table} WHERE {$column} = ?";
            $params = [$this->data[$field]];

            if ($excludeId !== null) {
                $sql .= " AND id != ?";
                $params[] = $excludeId;
            }

            $stmt = $db->prepare($sql);
            $stmt->execute($params);

            if ($stmt->fetchColumn() > 0) {
                $this->errors[$field] = "Cette valeur existe déjà";
            }
        }
        return $this;
    }

    public function fails(): bool {
        return !empty($this->errors);
    }

    public function getErrors(): array {
        return $this->errors;
    }

    public function validated(): array {
        if ($this->fails()) {
            ResponseHelper::error('Données invalides', 422, $this->errors);
        }
        return $this->data;
    }

    /**
     * Nettoyer et sécuriser les données d'entrée
     */
    public static function sanitize(array $data): array {
        $clean = [];
        foreach ($data as $key => $value) {
            if (is_string($value)) {
                $clean[$key] = htmlspecialchars(strip_tags(trim($value)), ENT_QUOTES, 'UTF-8');
            } elseif (is_array($value)) {
                $clean[$key] = self::sanitize($value);
            } else {
                $clean[$key] = $value;
            }
        }
        return $clean;
    }

    /**
     * Récupérer et décoder le body JSON de la requête
     */
    public static function getJsonBody(): array {
        $raw = file_get_contents('php://input');
        if (empty($raw)) return [];

        $data = json_decode($raw, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            ResponseHelper::error('Corps de la requête JSON invalide', 400);
        }

        return self::sanitize($data ?? []);
    }
}