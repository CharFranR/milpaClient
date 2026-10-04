import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/location_reporter.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/home.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_location_reporter.dart';
import '../../helpers/fake_user_repository.dart';

const CatalogCategory fruits = CatalogCategory(
  id: 'c1',
  name: 'Frutales',
  description: 'Frutas de temporada',
);

const CatalogCategory citrus = CatalogCategory(
  id: 'c2',
  name: 'Cítricos',
  description: 'Cítricos',
);

CatalogPage pageWith(List<CatalogItem> items, {int totalHits = 2}) {
  return CatalogPage(
    results: items,
    totalHits: totalHits,
    page: 1,
    pageSize: 4,
    totalPages: 1,
  );
}

CatalogItem itemOf(String id, String name) => CatalogItem(
  id: id,
  name: name,
  description: 'Producto de prueba',
  price: 120,
  type: '0',
  imageUrl: '',
  farmerId: 'f1',
  farmerName: 'Finca El Roble',
  farmerVerified: true,
  department: 'Masaya',
  municipality: 'Masate',
  latitude: 12.1364,
  longitude: -86.2514,
);

Future<void> pumpHome(
  WidgetTester tester, {
  required FakeCatalogRepository catalog,
  FakeLocationReporter? location,
}) async {
  final SessionController controller = SessionController(
    authRepository: FakeAuthRepository(),
    userRepository: FakeUserRepository(),
  );
  await controller.loadUser();

  await tester.pumpWidget(
    SessionScope(
      controller: controller,
      child: MaterialApp(
        home: BuyerHome(
          repository: catalog,
          locationReporter: location ?? FakeLocationReporter(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra el saludo con el usuario y el catálogo real', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository catalog = FakeCatalogRepository(
      categories: const <CatalogCategory>[fruits, citrus],
      page: pageWith(<CatalogItem>[
        itemOf('1', 'Tomates cherry'),
        itemOf('2', 'Aguacate hass'),
      ]),
    );

    await pumpHome(tester, catalog: catalog);
    await tester.pumpAndSettle();

    expect(find.text('Oscar 👋'), findsOneWidget);
    expect(find.text('Frutales'), findsOneWidget);
    expect(find.text('Cítricos'), findsOneWidget);
    expect(find.text('Tomates cherry'), findsOneWidget);
    expect(find.text('Aguacate hass'), findsOneWidget);
    expect(catalog.lastSort, CatalogSort.relevance);
  });

  testWidgets('sin ubicación concedida no pide coordenadas al server', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository catalog = FakeCatalogRepository(
      page: pageWith(<CatalogItem>[itemOf('1', 'Tomates cherry')], totalHits: 1),
    );
    final FakeLocationReporter location = FakeLocationReporter();

    await pumpHome(tester, catalog: catalog, location: location);
    await tester.pumpAndSettle();

    expect(location.grantedCalls, 1);
    expect(catalog.lastSort, CatalogSort.relevance);
    expect(catalog.lastLatitude, isNull);
    expect(find.textContaining('Compartí tu ubicación'), findsOneWidget);
  });

  testWidgets('con la ubicación concedida ordena por cercanía', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository catalog = FakeCatalogRepository(
      page: pageWith(<CatalogItem>[itemOf('1', 'Tomates cherry')], totalHits: 5),
    );
    final FakeLocationReporter location = FakeLocationReporter(
      result: const Coordinates(latitude: 12.1364, longitude: -86.2514),
    );

    await pumpHome(tester, catalog: catalog, location: location);
    await tester.pumpAndSettle();

    expect(catalog.lastSort, CatalogSort.proximity);
    expect(catalog.lastLatitude, 12.1364);
    expect(catalog.lastLongitude, -86.2514);
    expect(find.text('5 ofertas ordenadas por cercanía'), findsOneWidget);
  });

  testWidgets('muestra el error y deja reintentar', (
    WidgetTester tester,
  ) async {
    final FakeCatalogRepository catalog = FakeCatalogRepository()
      ..searchError = const ApiException(500, 'boom');

    await pumpHome(tester, catalog: catalog);
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar el inicio'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
