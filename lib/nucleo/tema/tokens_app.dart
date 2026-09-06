import 'package:flutter/material.dart';

/// Sistema de diseño "Atelier Pastel" para Pastelería M&G.
///
/// Paleta pastel de tono cálido y sofisticado: porcelana, rosa polvo,
/// salvia y arena dorada. Todo el UI de la app consume estos tokens para
/// mantener una identidad visual consistente y premium.
class Tokens {
  const Tokens._();

  // ───────────────────────── Color ─────────────────────────

  /// Lienzo general de la app: blanco porcelana cálido.
  static const Color lienzo = Color(0xFFFBF8F6);
  static const Color superficie = Color(0xFFFFFFFF);

  /// Superficie secundaria para bloques agrupados y estados vacíos.
  static const Color superficieSuave = Color(0xFFF6F0EB);

  /// Rosa polvo: color de marca. Suficientemente profundo para texto y botones.
  static const Color rosa = Color(0xFFC97B8E);
  static const Color rosaProfundo = Color(0xFFA85E71);
  static const Color rosaSuave = Color(0xFFF7E5E9);
  static const Color rosaVelo = Color(0xFFFCF2F4);

  /// Salvia: acento fresco y sereno.
  static const Color salvia = Color(0xFF7FA894);
  static const Color salviaProfundo = Color(0xFF5C8471);
  static const Color salviaSuave = Color(0xFFE5EFE9);

  /// Arena dorada: acento de lujo, usado para el Club M&G.
  static const Color arena = Color(0xFFC9A46B);
  static const Color arenaProfundo = Color(0xFF9A7B45);
  static const Color arenaSuave = Color(0xFFF6EDDD);

  /// Lavanda: acento terciario para tarjetas informativas.
  static const Color lavanda = Color(0xFF9A8CB8);
  static const Color lavandaSuave = Color(0xFFEFEAF7);

  // Tinta y neutros
  static const Color tinta = Color(0xFF2E2A28);
  static const Color tintaMedia = Color(0xFF6B615C);
  static const Color tintaSuave = Color(0xFF9A908A);
  static const Color linea = Color(0xFFEDE5DF);
  static const Color lineaFuerte = Color(0xFFE0D5CD);

  // Semánticos
  static const Color exito = Color(0xFF6E9E7E);
  static const Color exitoSuave = Color(0xFFE6F1EA);
  static const Color alerta = Color(0xFFC9994A);
  static const Color alertaSuave = Color(0xFFF8EFDC);
  static const Color peligro = Color(0xFFC2716B);
  static const Color peligroSuave = Color(0xFFF8E9E7);
  static const Color whatsapp = Color(0xFF3EA96B);

  // ───────────────────────── Gradientes ─────────────────────────

  /// Gradiente de marca para botones y elementos protagonistas.
  static const LinearGradient degradadoMarca = LinearGradient(
    colors: [Color(0xFFD48B9C), Color(0xFFBE6C82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Fondo suave de cabeceras: rosa velo hacia arena.
  static const LinearGradient degradadoAmanecer = LinearGradient(
    colors: [Color(0xFFFBEEF0), Color(0xFFF8F1E6), Color(0xFFEFF3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente oscuro y elegante de la tarjeta de crédito del Club.
  static const LinearGradient degradadoClub = LinearGradient(
    colors: [Color(0xFF3B3230), Color(0xFF251F1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ───────────────────────── Radios ─────────────────────────

  static const double radioXs = 10;
  static const double radioSm = 14;
  static const double radioMd = 20;
  static const double radioLg = 26;
  static const double radioXl = 34;
  static const double radioPildora = 999;

  // ───────────────────────── Espaciado ─────────────────────────

  static const double e1 = 4;
  static const double e2 = 8;
  static const double e3 = 12;
  static const double e4 = 16;
  static const double e5 = 20;
  static const double e6 = 24;
  static const double e8 = 32;
  static const double e10 = 40;
  static const double e12 = 48;

  // ───────────────────────── Sombras ─────────────────────────

  /// Elevación mínima: separa una tarjeta del lienzo sin ensuciarlo.
  static List<BoxShadow> get sombraSuave => [
    BoxShadow(
      color: const Color(0xFF6B4A3F).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Elevación media para tarjetas de producto y hojas flotantes.
  static List<BoxShadow> get sombraMedia => [
    BoxShadow(
      color: const Color(0xFF6B4A3F).withValues(alpha: 0.07),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: const Color(0xFF6B4A3F).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Halo de color bajo los botones principales.
  static List<BoxShadow> haloColor(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
