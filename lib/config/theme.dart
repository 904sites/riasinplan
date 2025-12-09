import 'package:flutter/material.dart';

class AppColors {
  static const Color ruby = Color(0xFF8C1312);
  static const Color poppyPink = Color(0xFFFF96B4);
  static const Color forest = Color(0xFF084509);
  static const Color brightBlue = Color(0xFF4FB6E5);
  static const Color sunshine = Color(0xFFFFDF59);
  static const Color dustyWhite = Color(0xFFF2EEE8);

  // MAPPING WARNA
  static const Color dustyOrchid = ruby;
  static const Color powderedLilac = poppyPink;
  static const Color sorbetStem = forest;
  static const Color textDark = forest;
  static const Color primaryText = forest;
  static const Color petalGlaze = poppyPink;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Warna Utama
      primaryColor: AppColors.ruby,

      scaffoldBackgroundColor: AppColors.dustyWhite,

      // Skema Warna
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ruby,
        primary: AppColors.ruby,
        secondary: AppColors.poppyPink,
        tertiary: AppColors.sunshine,
        surface: AppColors.dustyWhite,
        error: const Color(0xFFB00020),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ruby),
        titleTextStyle: TextStyle(
          color: AppColors.ruby,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif',
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ruby,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ruby,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 4,
          shadowColor: AppColors.poppyPink.withOpacity(0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.forest),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.poppyPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.poppyPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.ruby, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.forest),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: AppColors.ruby,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.forest),
        bodyLarge: TextStyle(color: AppColors.forest),
        titleLarge:
            TextStyle(color: AppColors.ruby, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sunshine.withOpacity(0.3),
        labelStyle: const TextStyle(color: AppColors.forest),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
