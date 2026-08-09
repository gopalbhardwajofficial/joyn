import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'joyn_colors.dart';

class JoynTypography {
  JoynTypography._();

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: JoynColors.primary,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: JoynColors.primary,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get heading => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: JoynColors.primary,
        height: 1.2,
        letterSpacing: -0.4,
      );

  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: JoynColors.secondaryText,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: JoynColors.primary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: JoynColors.primary,
      );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.1,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: JoynColors.secondaryText,
      );
}
