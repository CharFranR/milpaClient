import 'package:flutter_application_1/core/api_config.dart';

String? resolveImageSrc(String raw) {
  if (raw.trim().isEmpty) return null;
  final Uri? uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) return raw;
  return '${ApiConfig.apiBaseUrl}/images/${raw.split('/').last}';
}
