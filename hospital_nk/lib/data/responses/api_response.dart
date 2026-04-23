class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? pagination;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.pagination,
  });

  bool get hasErrors => errors != null && errors!.isNotEmpty;

  String get errorMessage {
    if (message != null) return message!;
    if (errors != null) {
      final allErrors = errors!.values.expand((e) {
        if (e is List) return e.map((item) => item.toString());
        return [e.toString()];
      }).toList();
      return allErrors.join(', ');
    }
    return 'Une erreur est survenue';
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromData != null ? fromData(json['data']) : null,
      errors: json['errors'],
    );
  }
}

class PaginationModel {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int? from;
  final int? to;

  PaginationModel({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.from,
    this.to,
  });

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPrevPage => currentPage > 1;

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 20,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'],
      to: json['to'],
    );
  }
}