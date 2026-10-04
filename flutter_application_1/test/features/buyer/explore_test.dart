import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/explore.dart';

import '../../helpers/fake_catalog_repository.dart';

CatalogItem buildItem({
  String id = 'item-1',
  String name = 'Tomate cherry',
  double price = 25.5,
  String farmerName = 'Finca El Roble',
  bool farmerVerified = false,
  String imageUrl = '',
}) => CatalogItem(
  id: id,
  name: name,
  description: 'Cosecha de la semana',
  price: price,
  type: 'vegetable',
  imageUrl: imageUrl,
  farmerId: 'farmer-1',
  farmerName: farmerName,
  farmerVerified: farmerVerified,
  department: 'Managua',
  municipality: 'Tipitapa',
  latitude: 12.5,
  longitude: -86.25,
);

CatalogPage buildPage({
  List<CatalogItem> results = const <CatalogItem>[],
  int totalHits = 0,
  int page = 1,
  int pageSize = 20,
  int totalPages = 0,
}) => CatalogPage(
  results: results,
  totalHits: totalHits,
  page: page,
  pageSize: pageSize,
  totalPages: totalPages,
);

const List<CatalogCategory> testCategories = <CatalogCategory>[
  CatalogCategory(id: 'cat-1', name: 'Verduras', description: 'Frescos'),
  CatalogCategory(id: 'cat-2', name: 'Frutas', description: 'De temporada'),
];

Widget wrap(FakeCatalogRepository repository) =>
    MaterialApp(home: BuyerExplore(repository: repository));

void main() {
  testWidgets('carga categorías, productos y conteo desde el servidor', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      page: buildPage(
        results: <CatalogItem>[buildItem()],
        totalHits: 3,
        totalPages: 1,
      ),
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Verduras'), findsOneWidget);
    expect(find.text('Frutas'), findsOneWidget);
    expect(find.text('Tomate cherry'), findsOneWidget);
    expect(find.text('Finca El Roble'), findsOneWidget);
    expect(find.text('3 productos encontrados'), findsOneWidget);
  });

  testWidgets('al tocar una categoría reconsulta con su id y Todos lo limpia', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      page: buildPage(
        results: <CatalogItem>[buildItem()],
        totalHits: 1,
        totalPages: 1,
      ),
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    await tester.tap(find.text('Verduras'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastCategoryId, 'cat-1');
    expect(repository.lastPage, 1);
    expect(repository.lastSort, CatalogSort.relevance);

    await tester.tap(find.text('Todos'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastCategoryId, isNull);
    expect(repository.searchCalls, 3);
  });

  testWidgets('busca con retraso al escribir', (WidgetTester tester) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'tomate');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(repository.lastTerm, 'tomate');
    expect(repository.lastPage, 1);
    expect(repository.searchCalls, 2);
  });

  testWidgets('busca de inmediato al enviar el texto', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'tomate');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repository.searchCalls, 1);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(repository.lastTerm, 'tomate');
    expect(repository.searchCalls, 2);
  });

  testWidgets('Precio alterna priceAsc y priceDesc y Relevancia reinicia', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    await tester.tap(find.text('Precio'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastSort, CatalogSort.priceAsc);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    await tester.tap(find.text('Precio'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastSort, CatalogSort.priceDesc);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

    await tester.tap(find.text('Relevancia'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastSort, CatalogSort.relevance);
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
  });

  testWidgets('Cargar más agrega la página siguiente y desaparece al final', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      pages: <int, CatalogPage>{
        1: buildPage(
          results: <CatalogItem>[
            buildItem(id: 'item-1', name: 'Tomate cherry'),
          ],
          totalHits: 2,
          page: 1,
          totalPages: 2,
        ),
        2: buildPage(
          results: <CatalogItem>[buildItem(id: 'item-2', name: 'Lechuga')],
          totalHits: 2,
          page: 2,
          totalPages: 2,
        ),
      },
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    expect(find.text('Cargar más'), findsOneWidget);

    await tester.ensureVisible(find.text('Cargar más'));
    await tester.pump();
    await tester.tap(find.text('Cargar más'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastPage, 2);
    expect(find.text('Tomate cherry'), findsOneWidget);
    expect(find.text('Lechuga'), findsOneWidget);
    expect(find.text('Cargar más'), findsNothing);
  });

  testWidgets('error inicial muestra Reintentar y reintenta la carga', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      page: buildPage(
        results: <CatalogItem>[buildItem()],
        totalHits: 1,
        totalPages: 1,
      ),
    )..searchError = Exception('sin conexión');

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    expect(find.text('No se pudo cargar el catálogo'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    repository.searchError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Tomate cherry'), findsOneWidget);
  });

  testWidgets('sin resultados muestra el estado vacío', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      page: buildPage(),
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    expect(find.text('0 productos encontrados'), findsOneWidget);
    expect(find.text('No encontramos productos'), findsOneWidget);
  });

  testWidgets('un producto sin imageSrc muestra el emoji de respaldo', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      page: buildPage(
        results: <CatalogItem>[buildItem(imageUrl: '')],
        totalHits: 1,
        totalPages: 1,
      ),
    );

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    expect(find.text('🌿'), findsOneWidget);
    expect(find.text('1 producto encontrado'), findsOneWidget);
  });

  testWidgets('si falla la paginación conserva resultados y avisa', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository repository = FakeCatalogRepository(
      categories: testCategories,
      pages: <int, CatalogPage>{
        1: buildPage(
          results: <CatalogItem>[buildItem()],
          totalHits: 2,
          page: 1,
          totalPages: 2,
        ),
      },
    )..paginationError = Exception('timeout');

    await tester.pumpWidget(wrap(repository));
    await tester.pump();

    await tester.ensureVisible(find.text('Cargar más'));
    await tester.pump();
    await tester.tap(find.text('Cargar más'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Tomate cherry'), findsOneWidget);
    expect(find.text('No pudimos cargar más productos'), findsOneWidget);
    expect(find.text('Cargar más'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
