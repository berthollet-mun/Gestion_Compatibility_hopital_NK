<?php
// api/config/Database.php

require_once __DIR__ . '/Config.php';

class Database {
    private static ?MySQLiConnection $instance = null;

    public static function getInstance(): MySQLiConnection {
        if (self::$instance === null) {
            $host    = Config::get('DB_HOST');
            $port    = Config::get('DB_PORT', '3306');
            $dbname  = Config::get('DB_NAME');
            $user    = Config::get('DB_USER');
            $pass    = Config::get('DB_PASS');
            $charset = Config::get('DB_CHARSET', 'utf8mb4');

            try {
                self::$instance = new MySQLiConnection($host, $user, $pass, $dbname, (int)$port, $charset);
            } catch (Throwable $e) {
                http_response_code(500);
                die(json_encode([
                    'success' => false,
                    'message' => 'Erreur de connexion à la base de données',
                    'error'   => Config::get('APP_DEBUG') === 'true'
                                 ? $e->getMessage() : 'Internal Server Error'
                ]));
            }
        }
        return self::$instance;
    }

    // Empêcher le clonage et la sérialisation (Singleton)
    private function __construct() {}
    private function __clone() {}
}

class MySQLiConnection {
    private mysqli $conn;

    public function __construct(string $host, string $user, string $pass, string $dbname, int $port, string $charset) {
        mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
        $this->conn = mysqli_init();
        $this->conn->real_connect($host, $user, $pass, $dbname, $port);
        $this->conn->set_charset($charset);
        $this->conn->query("SET NAMES {$charset} COLLATE utf8mb4_unicode_ci");
    }

    public function prepare(string $sql): MySQLiStatement {
        $stmt = $this->conn->prepare($sql);
        return new MySQLiStatement($stmt);
    }

    public function query(string $sql): MySQLiResult {
        $result = $this->conn->query($sql);
        return new MySQLiResult($result instanceof mysqli_result ? $result : null, $this->conn->affected_rows);
    }

    public function beginTransaction(): bool {
        return $this->conn->begin_transaction();
    }

    public function commit(): bool {
        return $this->conn->commit();
    }

    public function rollBack(): bool {
        return $this->conn->rollback();
    }

    public function lastInsertId(): int {
        return (int)$this->conn->insert_id;
    }
}

class MySQLiStatement {
    private mysqli_stmt $stmt;
    private ?mysqli_result $result = null;
    private int $affectedRows = 0;

    public function __construct(mysqli_stmt $stmt) {
        $this->stmt = $stmt;
    }

    public function execute(array $params = []): bool {
        if (!empty($params)) {
            $types = '';
            $refs = [];
            foreach ($params as $index => $value) {
                $types .= $this->detectType($value);
                $refs[$index] = $params[$index];
            }
            $bind = [$types];
            foreach ($refs as $index => &$valueRef) {
                $bind[] = &$valueRef;
            }
            $this->stmt->bind_param(...$bind);
        }

        $ok = $this->stmt->execute();
        $this->affectedRows = $this->stmt->affected_rows;
        $result = $this->stmt->get_result();
        $this->result = ($result instanceof mysqli_result) ? $result : null;
        return $ok;
    }

    public function fetch(): array|false {
        if (!$this->result) {
            return false;
        }
        $row = $this->result->fetch_assoc();
        return $row === null ? false : $row;
    }

    public function fetchAll(): array {
        if (!$this->result) {
            return [];
        }
        return $this->result->fetch_all(MYSQLI_ASSOC);
    }

    public function fetchColumn(int $column = 0): mixed {
        $row = $this->fetch();
        if ($row === false) {
            return false;
        }
        $values = array_values($row);
        return $values[$column] ?? false;
    }

    public function rowCount(): int {
        if ($this->result instanceof mysqli_result) {
            return $this->result->num_rows;
        }
        return $this->affectedRows;
    }

    private function detectType(mixed $value): string {
        return match (true) {
            is_int($value) => 'i',
            is_float($value) => 'd',
            is_null($value) => 's',
            default => 's',
        };
    }
}

class MySQLiResult {
    private ?mysqli_result $result;
    private int $affectedRows;

    public function __construct(?mysqli_result $result, int $affectedRows = 0) {
        $this->result = $result;
        $this->affectedRows = $affectedRows;
    }

    public function fetchAll(): array {
        if (!$this->result) {
            return [];
        }
        return $this->result->fetch_all(MYSQLI_ASSOC);
    }

    public function fetchColumn(int $column = 0): mixed {
        if (!$this->result) {
            return false;
        }
        $row = $this->result->fetch_row();
        if ($row === null) {
            return false;
        }
        return $row[$column] ?? false;
    }

    public function rowCount(): int {
        if ($this->result instanceof mysqli_result) {
            return $this->result->num_rows;
        }
        return $this->affectedRows;
    }
}
