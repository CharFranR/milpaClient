// Datos simulados para las pantallas del comprador.
//
// Mientras no exista backend, estas listas alimentan la UI con contenido
// realista para validar el diseño.

/// Producto del catálogo con su vendedor, precio y emoji ilustrativo.
class MockProduct {
  const MockProduct({
    required this.name,
    required this.seller,
    required this.price,
    required this.unit,
    required this.emoji,
    this.badge,
  });

  /// Nombre visible del producto.
  final String name;

  /// Productor o finca que lo ofrece.
  final String seller;

  /// Precio formateado con separador de miles.
  final String price;

  /// Unidad de venta, por ejemplo `/kg` o `/500ml`.
  final String unit;

  /// Emoji que hace de ilustración en la tarjeta.
  final String emoji;

  /// Etiqueta opcional: 'Orgánico' o 'Nuevo'.
  final String? badge;
}

/// Categoría del mercado con su emoji representativo.
class MockCategory {
  const MockCategory({required this.label, required this.emoji});

  /// Nombre de la categoría.
  final String label;

  /// Emoji que la representa.
  final String emoji;
}

/// Primer nombre del comprador; espeja la identidad de prueba de la pantalla
/// de perfil.
const String mockBuyerFirstName = 'Oscar';

/// Catálogo simulado de productos.
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

/// Categorías destacadas del mercado.
const List<MockCategory> mockCategories = [
  MockCategory(label: 'Verduras', emoji: '🥦'),
  MockCategory(label: 'Frutas', emoji: '🍅'),
  MockCategory(label: 'Lácteos', emoji: '🥛'),
  MockCategory(label: 'Carnes', emoji: '🥩'),
  MockCategory(label: 'Granos', emoji: '🌾'),
];

/// Productos resaltados en la sección "Destacados esta semana".
final List<MockProduct> mockFeatured = [mockProducts[4], mockProducts[5]];

/// Mensaje dentro de una conversación simulada.
class MockMessage {
  const MockMessage({
    required this.text,
    required this.fromBuyer,
    required this.time,
  });

  /// Contenido del mensaje.
  final String text;

  /// true = lo envió el comprador.
  final bool fromBuyer;

  /// Hora visible, por ejemplo '10:15' o 'Ahora'.
  final String time;
}

/// Conversación simulada del listado de mensajes.
class MockConversation {
  const MockConversation({
    required this.name,
    required this.emoji,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    required this.messages,
  });

  /// Nombre del productor o finca.
  final String name;

  /// Emoji que hace de avatar.
  final String emoji;

  /// Último mensaje mostrado en el listado.
  final String lastMessage;

  /// Hora o día del último mensaje.
  final String time;

  /// Mensajes sin leer; 0 oculta el contador.
  final int unread;

  /// Mensajes de la conversación, del más antiguo al más reciente.
  final List<MockMessage> messages;
}

/// Conversaciones simuladas de la bandeja del comprador.
const List<MockConversation> mockConversations = [
  MockConversation(
    name: 'Finca El Roble',
    emoji: '👩‍🌾',
    lastMessage: 'Claro, tenemos disponibles 80 kg para la...',
    time: '10:32',
    unread: 2,
    messages: [
      MockMessage(
        text: 'Buenos días, me interesa comprar tomates cherry. ¿Tienen disponibilidad para la próxima semana?',
        fromBuyer: false,
        time: '10:15',
      ),
      MockMessage(
        text: 'Claro que sí, tenemos disponibles 80 kg para la próxima semana. ¿Cuántos necesitas?',
        fromBuyer: true,
        time: '10:17',
      ),
      MockMessage(
        text: 'Necesito unos 20 kg. ¿Cuál es el precio por kilo?',
        fromBuyer: false,
        time: '10:20',
      ),
      MockMessage(
        text: 'El precio es \$4,500 por kg. Si llevas más de 15 kg te hacemos un descuento del 5%. ¿Te parece bien?',
        fromBuyer: true,
        time: '10:22',
      ),
      MockMessage(
        text: 'Perfecto, me interesa. ¿Hacen entrega a domicilio?',
        fromBuyer: false,
        time: '10:28',
      ),
    ],
  ),
  MockConversation(
    name: 'Hacienda La Paz',
    emoji: '💐',
    lastMessage: 'Muchas gracias por su interés en nuestros pro...',
    time: 'Ayer',
    messages: [
      MockMessage(
        text: '¿Tienen aguacate hass disponible la próxima semana?',
        fromBuyer: true,
        time: '08:40',
      ),
      MockMessage(
        text: 'Muchas gracias por su interés en nuestros productos.',
        fromBuyer: false,
        time: '09:12',
      ),
    ],
  ),
  MockConversation(
    name: 'Cooperativa Sur',
    emoji: '🌾',
    lastMessage: 'Le enviamos los precios actualizados.',
    time: 'Mar',
    messages: [
      MockMessage(
        text: 'Le enviamos los precios actualizados.',
        fromBuyer: false,
        time: '11:05',
      ),
    ],
  ),
  MockConversation(
    name: 'Bio Campo',
    emoji: '🌱',
    lastMessage: '¡Perfecto! Lo contactamos mañana.',
    time: 'Lun',
    unread: 1,
    messages: [
      MockMessage(
        text: '¿Me confirman disponibilidad de espinaca?',
        fromBuyer: true,
        time: '16:40',
      ),
      MockMessage(
        text: '¡Perfecto! Lo contactamos mañana.',
        fromBuyer: false,
        time: '17:02',
      ),
    ],
  ),
  MockConversation(
    name: 'Granja Norte',
    emoji: '🐓',
    lastMessage: 'Disponemos de pollos de engorde.',
    time: 'Dom',
    messages: [
      MockMessage(
        text: '¿Tienen pechuga fresca esta semana?',
        fromBuyer: true,
        time: '10:10',
      ),
      MockMessage(
        text: 'Disponemos de pollos de engorde.',
        fromBuyer: false,
        time: '10:35',
      ),
    ],
  ),
];
