import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/company/company_models.dart';

class CompanyRepository {
  CompanyRepository({required ApiClient apiClient, required this._tokenStore})
    : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<Company>> fetchByOwner(String ownerId) async {
    final dynamic json = await _api.get(
      '/companies',
      query: <String, String>{'owner_id': ownerId},
    );
    return _list(json);
  }

  Future<Company> fetchById(String id) async {
    final dynamic json = await _api.get('/companies/$id');
    return Company.fromJson(json as Map<String, dynamic>);
  }

  Future<Company> create(CompanyDraft draft) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post(
      '/companies',
      body: draft.toJson(),
      token: token,
    );
    return Company.fromJson(json as Map<String, dynamic>);
  }

  Future<void> update(String id, CompanyDraft draft) async {
    final String token = await _readTokenOrThrow();
    await _api.patch('/companies/$id', body: draft.toJson(), token: token);
  }

  Future<String> _readTokenOrThrow() async {
    final String? token = await _tokenStore.readToken();
    if (token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    return token;
  }

  List<Company> _list(dynamic json) => json is List
      ? json.whereType<Map<String, dynamic>>().map(Company.fromJson).toList()
      : <Company>[];
}
