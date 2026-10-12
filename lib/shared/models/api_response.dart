class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? dataParser,
  }) {
    final rawData = json['data'];

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: rawData == null || dataParser == null ? null : dataParser(rawData),
    );
  }
}
