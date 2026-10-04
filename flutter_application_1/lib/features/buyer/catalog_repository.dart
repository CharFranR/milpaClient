import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';

class CatalogRepository {
  CatalogRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<CatalogPage> search({
    String term = '',
    String? categoryId,
    CatalogSort sort = CatalogSort.relevance,
    int page = 1,
    int pageSize = 20,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, String> query = <String, String>{
      'term': ?(term.isEmpty ? null : term),
      'category_id': ?(categoryId == null || categoryId.isEmpty
          ? null
          : categoryId),
      'sort': sort.wire,
      'page': '$page',
      'page_size': '$pageSize',
      'lat': ?(latitude == null ? null : '$latitude'),
      'lng': ?(longitude == null ? null : '$longitude'),
    };
    final dynamic json = await _api.get('/search', query: query);
    return CatalogPage.fromJson(json as Map<String, dynamic>);
  }

  Future<List<CatalogCategory>> fetchCategories() async {
    final dynamic json = await _api.get('/categories');
    return (json as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CatalogCategory.fromJson)
        .toList();
  }
}
