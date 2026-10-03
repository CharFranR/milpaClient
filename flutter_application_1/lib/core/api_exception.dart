class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  const NetworkException([
    this.message = 'No se pudo conectar con el servidor',
  ]);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}
