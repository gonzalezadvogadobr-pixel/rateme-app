import 'package:flutter/material.dart';

class AppTheme {
  // ── Cores principais — Light Clean ─────────────────────────────────────────
  static const Color bgPrimary   = Color(0xFFF8F8F8);   // fundo geral branco-gelo
  static const Color bgSecondary = Color(0xFFFFFFFF);   // app bar / surfaces brancas
  static const Color bgCard      = Color(0xFFFFFFFF);   // cards brancos
  static const Color bgSurface   = Color(0xFFF0F0F5);   // inputs, superfícies suaves

  // Roxo/Rosa — mantidos como identidade do app
  static const Color purple      = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFF9F67FF);
  static const Color pink        = Color(0xFFEC4899);
  static const Color pinkLight   = Color(0xFFF472B6);

  // Textos — escuros sobre fundo branco
  static const Color textPrimary   = Color(0xFF1A1A2E);  // quase preto
  static const Color textSecondary = Color(0xFF4A4A6A);  // cinza escuro
  static const Color textMuted     = Color(0xFF9090A8);  // cinza médio

  // Premiação
  static const Color goldColor   = Color(0xFFFFD700);
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color bronzeColor = Color(0xFFCD7F32);

  // Semânticas
  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient gradientPurplePink = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBg = LinearGradient(
    colors: [bgPrimary, bgSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: purple,
        secondary: pink,
        surface: bgCard,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.07),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: purple,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDE8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: purple,
        unselectedItemColor: textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: purple,
        thumbColor: pink,
        inactiveTrackColor: bgSurface,
        overlayColor: purple.withValues(alpha: 0.15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return pink;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return pink.withValues(alpha: 0.4);
          }
          return bgSurface;
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEF5),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall:    TextStyle(color: textSecondary,fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(color: textPrimary),
        bodyMedium:    TextStyle(color: textSecondary),
        bodySmall:     TextStyle(color: textMuted),
        labelLarge:    TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(color: textSecondary),
        labelSmall:    TextStyle(color: textMuted),
      ),
    );
  }
}
