<?php
// api/helpers/ResponseHelper.php

class ResponseHelper {

    public static function success(
        mixed $data = null,
        string $message = 'Succès',
        int $code = 200,
        array $meta = []
    ): void {
        http_response_code($code);
        $response = [
            'success'   => true,
            'message'   => $message,
            'data'      => $data,
            'timestamp' => date('Y-m-d H:i:s'),
        ];
        if (!empty($meta)) {
            $response['meta'] = $meta;
        }
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit();
    }

    public static function error(
        string $message = 'Erreur',
        int $code = 400,
        mixed $errors = null
    ): void {
        http_response_code($code);
        $response = [
            'success'   => false,
            'message'   => $message,
            'timestamp' => date('Y-m-d H:i:s'),
        ];
        if ($errors !== null) {
            $response['errors'] = $errors;
        }
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit();
    }

    public static function paginated(
        array $data,
        int $total,
        int $page,
        int $perPage,
        string $message = 'Liste récupérée'
    ): void {
        self::success($data, $message, 200, [
            'pagination' => [
                'total'        => $total,
                'per_page'     => $perPage,
                'current_page' => $page,
                'total_pages'  => (int) ceil($total / $perPage),
                'has_next'     => ($page * $perPage) < $total,
                'has_prev'     => $page > 1,
            ]
        ]);
    }
}