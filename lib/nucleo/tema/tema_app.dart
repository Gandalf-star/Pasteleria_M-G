import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemaApp {
  // Paleta "Macaron": Colores pastel frescos y deliciosos
  static const Color _rosaFresa = Color(0xFFFF8FA3); // Rosa Fresa pastel
  static const Color _rosaClaro = Color(0xFFFFB3C1); // Container Rosa
  static const Color _verdeMenta = Color(0xFF84DCC6); // Menta Pistacho
  static const Color _mentaClaro = Color(0xFFA5FFD6); // Container Menta
  static const Color _cremaVainilla = Color(0xFFFFF3B0); // Crema / Vainilla
  static const Color _cremaClaro = Color(0xFFFFF9E6); // Container Crema
  static const Color _fondoBlanco = Color(0xFFFBFBFB); // Fondo súper limpio

  static ThemeData get temaClaro {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: _rosaFresa,
        primaryContainer: _rosaClaro,
        secondary: _verdeMenta,
        secondaryContainer: _mentaClaro,
        tertiary: _cremaVainilla,
        tertiaryContainer: _cremaClaro,
      ),
      scaffoldBackground: _fondoBlanco,
      surface: Colors.white,
      surfaceTint: Colors.white,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 0,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 0,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        
        // Estilo de inputs súper redondos y suaves (estilo Apple/Moderno)
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 24,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorFocusedBorderWidth: 2.0,
        inputDecoratorFillColor: Colors.white,
        
        // Estilo de tarjetas y botones amigables
        chipRadius: 20,
        cardRadius: 24,
        dialogRadius: 28,
        bottomSheetRadius: 32,
        fabRadius: 20,
        elevatedButtonRadius: 24,
        outlinedButtonRadius: 24,
        filledButtonRadius: 24,
        textButtonRadius: 24,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF2D3142)),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF2D3142)),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF2D3142)),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF2D3142)),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF2D3142)),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF4F5D75)),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF2D3142)),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF4F5D75)),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFF4F5D75)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF4F5D75)),
      ),
    );
  }

  // Mantenemos un tema oscuro por consistencia, pero la app usará el claro por defecto.
  static ThemeData get temaOscuro {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: _rosaFresa,
        primaryContainer: Color(0xFF881337), 
        secondary: _verdeMenta,
        secondaryContainer: Color(0xFF0F5257), 
        tertiary: _cremaVainilla,
        tertiaryContainer: Color(0xFF7A6C12), 
      ),
      scaffoldBackground: const Color(0xFF1C1917),
      surface: const Color(0xFF292524),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 0,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 0,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 24,
        inputDecoratorFocusedBorderWidth: 2.0,
        chipRadius: 20,
        cardRadius: 24,
        dialogRadius: 28,
        bottomSheetRadius: 32,
        fabRadius: 20,
        elevatedButtonRadius: 24,
        outlinedButtonRadius: 24,
        filledButtonRadius: 24,
        textButtonRadius: 24,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white70),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white70),
      ),
    );
  }
}
