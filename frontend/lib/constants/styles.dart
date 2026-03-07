import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppStyles {
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF8D8D8D),
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static TextStyle welcomeSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB0B0B0),
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration accentCardDecoration = BoxDecoration(
    color: AppColors.accentGreen,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
