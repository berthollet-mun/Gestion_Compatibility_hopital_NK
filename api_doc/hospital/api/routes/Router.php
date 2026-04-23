<?php
// api/routes/Router.php

class Router {
    private array $routes = [];

    public function get(string $path, callable $handler): void {
        $this->routes[] = ['GET', $path, $handler];
    }

    public function post(string $path, callable $handler): void {
        $this->routes[] = ['POST', $path, $handler];
    }

    public function put(string $path, callable $handler): void {
        $this->routes[] = ['PUT', $path, $handler];
    }

    public function delete(string $path, callable $handler): void {
        $this->routes[] = ['DELETE', $path, $handler];
    }

    public function dispatch(): void {
        $method = $_SERVER['REQUEST_METHOD'];

        // Gérer CORS preflight
        if ($method === 'OPTIONS') {
            http_response_code(200);
            exit();
        }

        // ─── RÉCUPÉRER L'URI PROPREMENT ───────────────────────
        $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/';
        $scriptName = $_SERVER['SCRIPT_NAME'] ?? '';
        $basePath = rtrim(str_replace('\\', '/', dirname($scriptName)), '/');

        // Ex: /hospital/api/index.php => basePath /hospital/api
        if ($basePath && $basePath !== '/' && str_starts_with($uri, $basePath)) {
            $uri = substr($uri, strlen($basePath));
        }

        // Supprimer index.php de l'URI si present
        $uri = str_replace('/index.php', '', $uri);

        // Accepter /api/... ou /...
        $uri = preg_replace('#^/api#', '', $uri);

        // Normaliser
        $path = '/' . trim((string)$uri, '/');
        if ($path === '') $path = '/';

        // ─── MATCHER LA ROUTE ─────────────────────────────────
        foreach ($this->routes as [$routeMethod, $routePath, $handler]) {
            if ($routeMethod !== $method) continue;

            // Convertir {id} en regex
            $pattern = preg_replace('/\{([a-zA-Z_]+)\}/', '([^/]+)', $routePath);
            $pattern = '#^' . $pattern . '$#';

            if (preg_match($pattern, $path, $matches)) {
                array_shift($matches);
                call_user_func_array($handler, $matches);
                return;
            }
        }

        // ─── ROUTE NON TROUVÉE ────────────────────────────────
        http_response_code(404);
        echo json_encode([
            'success'   => false,
            'message'   => "Route '{$method} {$path}' introuvable",
            'uri_recu'  => $uri,
            'timestamp' => date('Y-m-d H:i:s')
        ], JSON_UNESCAPED_UNICODE);
    }
}