import 'package:flutter/material.dart';
import 'screens/table_selection_screen.dart';
import 'utils/colors.dart';
import 'utils/turkish_strings.dart';

void main() {
  runApp(const KafePosApp());
}

class KafePosApp extends StatelessWidget {
  const KafePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TurkishStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.cardBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TableSelectionScreen(),
    );
  }
}