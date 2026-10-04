import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/catalog_repository.dart';

const CatalogPage emptyCatalogPage = CatalogPage(
  results: <CatalogItem>[],
  totalHits: 0,
  page: 1,
  pageSize: 20,
  totalPages: 0,
);

class FakeCatalogRepository extends CatalogRepository {
  FakeCatalogRepository({
    this.categories = const <CatalogCategory>[],
    this.page = emptyCatalogPage,
    Map<int, CatalogPage>? pages,
  }) : pages = pages ?? <int, CatalogPage>{},
       super(apiClient: ApiClient());

  List<CatalogCategory> categories;
  CatalogPage page;
  final Map<int, CatalogPage> pages;
  Object? categoriesError;
  Object? searchError;
  Object? paginationError;

  int categoryCalls = 0;
  int searchCalls = 0;
  String? lastTerm;
  String? lastCategoryId;
  CatalogSort? lastSort;
  int? lastPage;
  int? lastPageSize;

  @override
  Future<List<CatalogCategory>> fetchCategories() async {
    categoryCalls++;
    final Object? error = categoriesError;
    if (error != null) throw error;
    return categories;
  }

  @override
  Future<CatalogPage> search({
    String term = '',
    String? categoryId,
    CatalogSort sort = CatalogSort.relevance,
    int page = 1,
    int pageSize = 20,
  }) async {
    searchCalls++;
    lastTerm = term;
    lastCategoryId = categoryId;
    lastSort = sort;
    lastPage = page;
    lastPageSize = pageSize;
    if (page > 1) {
      final Object? paginationFailure = paginationError;
      if (paginationFailure != null) throw paginationFailure;
    }
    final Object? searchFailure = searchError;
    if (searchFailure != null) throw searchFailure;
    return pages[page] ?? this.page;
  }
}
