class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  ApiException(this.message, {this.code, this.data});

  @override
  String toString() =>
      'ApiException: $message${code != null ? ' (code: $code)' : ''}';
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
