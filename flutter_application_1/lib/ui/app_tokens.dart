import 'package:flutter/material.dart';

/// Escala de espaciado vertical y horizontal.
///
/// Un solo lugar para decidir cuánto separa cada cosa, en vez de repetir
/// números sueltos por cada pantalla.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Radios de esquina. [md] es el radio "estándar" de controles.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double pill = 999;
}

/// Familias tipográficas de la app.
///
/// [heading] cubre títulos y encabezados; [body] cubre subtítulos, párrafos
/// y textos de apoyo. Hoy apuntan a Inter (libre); si el equipo licencia la
/// tipografía definitiva del diseño, alcanza con cambiar estos nombres.
class AppFonts {
  AppFonts._();

  static const String heading = 'InterDisplay';

  static const String body = 'Inter';
}

/// Paleta de colores de la app.
class AppColors {
  AppColors._();

  static const Color dark = Color(0xff1d1d1b);

  static const Color blackmodeBackgrund = Color(0xff075809);

  static const Color whitemodeBackgrund = Color(0xffF9F6EE);

  static const Color blackGreen = Color(0xff075809);

  static const Color whiteGreen = Color(0xff35d239);

  static const Color yelow = Color(0xffd2e749);
}

/// Opacidades ya usadas en `login.dart` sobre `AppColors.dark`.
///
/// Son `final` y no `const` porque `Color.withValues` no es un método const.
class AppAlpha {
  AppAlpha._();

  /// Bordes de campos y contenedores neutrales.
  static const double border = 0.2;

  /// Texto de ayuda dentro de un campo vacío.
  static const double hint = 0.35;

  /// Texto secundario o deshabilitado.
  static const double muted = 0.5;

  /// Texto secundario legible (subtítulos, descripciones).
  static const double secondary = 0.7;
}

/// Colores derivados de [AppColors.dark] con opacidad.
///
/// Centralizarlos evita que cada pantalla invente su propio gris y mantiene
/// el mismo aspecto que `login.dart`.
class AppTints {
  AppTints._();

  static final Color border = AppColors.dark.withValues(alpha: AppAlpha.border);
  static final Color hint = AppColors.dark.withValues(alpha: AppAlpha.hint);
  static final Color muted = AppColors.dark.withValues(alpha: AppAlpha.muted);
  static final Color secondary = AppColors.dark.withValues(
    alpha: AppAlpha.secondary,
  );
}

/// Estilos de texto de la app.
///
/// Los que solo usan `AppColors` directamente son `const`; los que dependen de
/// una opacidad tienen que ser `final` (`withValues` no es const).
class AppText {
  AppText._();

  /// Título de pantalla. Ej. "Crear cuenta".
  static const TextStyle screenTitle = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.dark,
  );

  /// Título de sección dentro del formulario. Ej. "Datos personales".
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.dark,
  );

  /// Label flotante encima de un campo.
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.dark,
  );

  /// Texto de párrafo / controles.
  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    color: AppColors.dark,
  );

  /// Párrafo secundario, un poco más apagado.
  static final TextStyle bodySecondary = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    color: AppTints.secondary,
  );

  /// Texto auxiliar: descripciones de tarjetas, notas.
  static final TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    color: AppTints.muted,
  );

  /// Placeholder dentro de un campo vacío.
  static final TextStyle hint = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    color: AppTints.hint,
  );

  /// Etiqueta de botón principal (sobre fondo verde).
  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// Acción de texto tipo link: "Iniciar sesión".
  static const TextStyle link = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.blackGreen,
  );

  /// Título grande de tarjeta o cabecera de contenido. Ej. nombre en perfil.
  static const TextStyle headline = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.dark,
  );

  /// Título de fila o etiqueta dentro de una tarjeta.
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.dark,
  );

  static const TextStyle appBarText = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 22,
    color: AppColors.whitemodeBackgrund,
    fontWeight: FontWeight.bold,
  );
}
