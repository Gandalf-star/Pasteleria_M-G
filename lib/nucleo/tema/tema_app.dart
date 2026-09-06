import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens_app.dart';

/// Tema "Atelier Pastel": pastelería artesanal de gama alta.
///
/// Serif editorial (Fraunces) para títulos y precios, sans neutra (Inter)
/// para el resto de la interfaz. Los valores concretos viven en [Tokens].
class TemaApp {
  const TemaApp._();

  static const ColorScheme _esquemaClaro = ColorScheme(
    brightness: Brightness.light,
    primary: Tokens.rosa,
    onPrimary: Colors.white,
    primaryContainer: Tokens.rosaSuave,
    onPrimaryContainer: Tokens.rosaProfundo,
    secondary: Tokens.salvia,
    onSecondary: Colors.white,
    secondaryContainer: Tokens.salviaSuave,
    onSecondaryContainer: Tokens.salviaProfundo,
    tertiary: Tokens.arena,
    onTertiary: Colors.white,
    tertiaryContainer: Tokens.arenaSuave,
    onTertiaryContainer: Tokens.arenaProfundo,
    error: Tokens.peligro,
    onError: Colors.white,
    errorContainer: Tokens.peligroSuave,
    onErrorContainer: Color(0xFF8C4741),
    surface: Tokens.superficie,
    onSurface: Tokens.tinta,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Tokens.lienzo,
    surfaceContainer: Color(0xFFF8F3EF),
    surfaceContainerHigh: Tokens.superficieSuave,
    surfaceContainerHighest: Color(0xFFF1EAE4),
    onSurfaceVariant: Tokens.tintaMedia,
    outline: Tokens.lineaFuerte,
    outlineVariant: Tokens.linea,
    shadow: Color(0xFF6B4A3F),
    scrim: Color(0xFF2E2A28),
    inverseSurface: Tokens.tinta,
    onInverseSurface: Tokens.lienzo,
    inversePrimary: Tokens.rosaSuave,
  );

  static TextTheme _tipografia(ColorScheme esquema) {
    final base = GoogleFonts.interTextTheme();
    TextStyle serif({
      required double tam,
      FontWeight peso = FontWeight.w600,
      double espaciado = -0.4,
      double? altura,
      Color? color,
    }) => GoogleFonts.fraunces(
      fontSize: tam,
      fontWeight: peso,
      letterSpacing: espaciado,
      height: altura,
      color: color ?? esquema.onSurface,
    );

    TextStyle sans({
      required double tam,
      FontWeight peso = FontWeight.w400,
      double espaciado = 0,
      double? altura,
      Color? color,
    }) => GoogleFonts.inter(
      fontSize: tam,
      fontWeight: peso,
      letterSpacing: espaciado,
      height: altura,
      color: color ?? esquema.onSurface,
    );

    return base.copyWith(
      displayLarge: serif(tam: 46, peso: FontWeight.w700, espaciado: -1.4),
      displayMedium: serif(tam: 38, peso: FontWeight.w700, espaciado: -1.0),
      displaySmall: serif(tam: 31, peso: FontWeight.w600, espaciado: -0.7),
      headlineLarge: serif(tam: 27, peso: FontWeight.w600, espaciado: -0.6),
      headlineMedium: serif(tam: 23, peso: FontWeight.w600, espaciado: -0.4),
      headlineSmall: serif(tam: 20, peso: FontWeight.w600, espaciado: -0.3),
      titleLarge: serif(tam: 18, peso: FontWeight.w600, espaciado: -0.2),
      titleMedium: sans(tam: 16, peso: FontWeight.w600, espaciado: -0.1),
      titleSmall: sans(tam: 14, peso: FontWeight.w600),
      bodyLarge: sans(tam: 16, altura: 1.55, color: Tokens.tintaMedia),
      bodyMedium: sans(tam: 14.5, altura: 1.55, color: Tokens.tintaMedia),
      bodySmall: sans(tam: 13, altura: 1.5, color: Tokens.tintaSuave),
      labelLarge: sans(tam: 15, peso: FontWeight.w600, espaciado: 0.1),
      labelMedium: sans(tam: 13, peso: FontWeight.w600, espaciado: 0.2),
      labelSmall: sans(
        tam: 11,
        peso: FontWeight.w600,
        espaciado: 0.8,
        color: Tokens.tintaSuave,
      ),
    );
  }

  static ThemeData get temaClaro {
    const esquema = _esquemaClaro;
    final texto = _tipografia(esquema);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Tokens.lienzo,
      canvasColor: Tokens.lienzo,
      textTheme: texto,
      primaryTextTheme: texto,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Tokens.tinta,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: texto.titleLarge,
        iconTheme: const IconThemeData(color: Tokens.tinta, size: 22),
      ),

      dividerTheme: const DividerThemeData(
        color: Tokens.linea,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: Tokens.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioLg),
          side: const BorderSide(color: Tokens.linea),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Tokens.e5,
          vertical: Tokens.e4,
        ),
        hintStyle: texto.bodyMedium?.copyWith(color: Tokens.tintaSuave),
        labelStyle: texto.bodyMedium?.copyWith(color: Tokens.tintaMedia),
        floatingLabelStyle: texto.labelMedium?.copyWith(color: Tokens.rosa),
        prefixIconColor: Tokens.tintaSuave,
        suffixIconColor: Tokens.tintaSuave,
        border: _borde(Tokens.linea),
        enabledBorder: _borde(Tokens.linea),
        focusedBorder: _borde(Tokens.rosa, ancho: 1.6),
        errorBorder: _borde(Tokens.peligro),
        focusedErrorBorder: _borde(Tokens.peligro, ancho: 1.6),
        errorStyle: texto.bodySmall?.copyWith(color: Tokens.peligro),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Tokens.rosa,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.e6),
          textStyle: texto.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioSm),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Tokens.rosa,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.e6),
          textStyle: texto.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioSm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Tokens.tinta,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: Tokens.e6),
          textStyle: texto.labelLarge,
          side: const BorderSide(color: Tokens.lineaFuerte),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioSm),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Tokens.rosaProfundo,
          textStyle: texto.labelMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioXs),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: Tokens.tintaMedia),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Tokens.rosa,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        extendedTextStyle: texto.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioPildora),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Tokens.superficie,
        side: const BorderSide(color: Tokens.linea),
        labelStyle: texto.labelMedium!,
        shape: const StadiumBorder(),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: Tokens.tintaMedia,
        contentPadding: EdgeInsets.symmetric(horizontal: Tokens.e5),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Tokens.rosa : Colors.white,
        ),
        side: const BorderSide(color: Tokens.lineaFuerte, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Tokens.rosa,
        linearTrackColor: Tokens.linea,
        circularTrackColor: Colors.transparent,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Tokens.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: texto.headlineSmall,
        contentTextStyle: texto.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioLg),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tokens.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.radioXl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Tokens.tinta,
        contentTextStyle: texto.bodyMedium?.copyWith(color: Colors.white),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioSm),
        ),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: Tokens.lienzo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(Tokens.radioXl),
          ),
        ),
      ),

      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        iconColor: Tokens.rosa,
        collapsedIconColor: Tokens.tintaSuave,
        tilePadding: EdgeInsets.symmetric(horizontal: Tokens.e5),
        childrenPadding: EdgeInsets.zero,
      ),
    );
  }

  static OutlineInputBorder _borde(Color color, {double ancho = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radioSm),
        borderSide: BorderSide(color: color, width: ancho),
      );

  /// Variante oscura conservada por compatibilidad; la app usa el tema claro.
  static ThemeData get temaOscuro {
    final base = temaClaro;
    const esquema = ColorScheme.dark(
      primary: Color(0xFFE0A0AF),
      onPrimary: Color(0xFF3A1F26),
      primaryContainer: Color(0xFF5A343E),
      onPrimaryContainer: Color(0xFFF7E5E9),
      secondary: Color(0xFF9CC3B0),
      onSecondary: Color(0xFF1E3229),
      tertiary: Color(0xFFDFC08A),
      onTertiary: Color(0xFF3A2E17),
      surface: Color(0xFF221E1D),
      onSurface: Color(0xFFF2ECE8),
      onSurfaceVariant: Color(0xFFBDB2AC),
      outline: Color(0xFF524945),
      outlineVariant: Color(0xFF3A3331),
      error: Color(0xFFE1948E),
      onError: Color(0xFF3A1B19),
    );

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: esquema,
      scaffoldBackgroundColor: const Color(0xFF1A1716),
      canvasColor: const Color(0xFF1A1716),
      textTheme: _tipografia(esquema),
    );
  }
}
