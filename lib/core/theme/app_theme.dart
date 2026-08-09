import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'joyn_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: JoynColors.background,
      colorScheme: const ColorScheme.light(
        primary: JoynColors.primary,
        onPrimary: Colors.white,
        surface: JoynColors.background,
        onSurface: JoynColors.primary,
        outline: JoynColors.border,
        error: JoynColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: JoynColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: JoynColors.primary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: JoynColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: JoynColors.primary,
        size: 22,
      ),
    );
  }
}
