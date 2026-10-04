class MockProduct {
  const MockProduct({
    required this.name,
    required this.seller,
    required this.price,
    required this.unit,
    required this.emoji,
    this.badge,
  });

  final String name;
  final String seller;
  final String price;
  final String unit;
  final String emoji;
  final String? badge;
}

class MockCategory {
  const MockCategory({required this.label, required this.emoji});

  final String label;
  final String emoji;
}

const String mockBuyerFirstName = 'Oscar';

const List<MockProduct> mockProducts = [
  MockProduct(
    name: 'Espinaca baby',
    seller: 'Bio Campo',
    price: '\$3.800',
    unit: '/kg',
    emoji: '🥦',
    badge: 'Orgánico',
  ),
  MockProduct(
    name: 'Mandarina',
    seller: 'Finca Sol',
    price: '\$2.500',
    unit: '/kg',
    emoji: '🍊',
  ),
  MockProduct(
    name: 'Yogur natural',
    seller: 'Lácteos Boyacá',
    price: '\$5.500',
    unit: '/500ml',
    emoji: '🥛',
    badge: 'Nuevo',
  ),
  MockProduct(
    name: 'Pechuga fresca',
    seller: 'Granja Norte',
    price: '\$9.000',
    unit: '/kg',
    emoji: '🍗',
  ),
  MockProduct(
    name: 'Tomates cherry',
    seller: 'Finca El Roble',
    price: '\$4.500',
    unit: '/kg',
    emoji: '🍅',
    badge: 'Orgánico',
  ),
  MockProduct(
    name: 'Aguacate hass',
    seller: 'Hacienda Verde',
    price: '\$6.000',
    unit: '/kg',
    emoji: '🥑',
    badge: 'Nuevo',
  ),
  MockProduct(
    name: 'Plátano maduro',
    seller: 'Finca La Esperanza',
    price: '\$1.800',
    unit: '/kg',
    emoji: '🍌',
  ),
  MockProduct(
    name: 'Queso fresco',
    seller: 'Lácteos Boyacá',
    price: '\$4.200',
    unit: '/kg',
    emoji: '🧀',
  ),
];

const List<MockCategory> mockCategories = [
  MockCategory(label: 'Verduras', emoji: '🥦'),
  MockCategory(label: 'Frutas', emoji: '🍅'),
  MockCategory(label: 'Lácteos', emoji: '🥛'),
  MockCategory(label: 'Carnes', emoji: '🥩'),
  MockCategory(label: 'Granos', emoji: '🌾'),
];

final List<MockProduct> mockFeatured = [mockProducts[4], mockProducts[5]];
