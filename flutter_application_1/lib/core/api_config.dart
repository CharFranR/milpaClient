class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://158.158.36.211:8080/api/v1',
  );

  static Uri webSocketUri(String conversationId) =>
      webSocketUriFrom(apiBaseUrl, conversationId);

  static Uri webSocketUriFrom(String baseUrl, String conversationId) {
    final Uri base = Uri.parse(baseUrl);
    final String basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '$basePath/ws/$conversationId',
    );
  }
}
