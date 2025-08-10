import 'package:flutter/material.dart';

/// やんわり伝言 デザインシステム - Figmaベース
class YanwariDesignSystem {
  // Private constructor to prevent instantiation
  YanwariDesignSystem._();

  // ===== カラーパレット =====
  // Figma Primary Colors
  static const Color primaryColor = Color(0xFFCDE6FF);
  static const Color primaryColorDark = Color(0xFFB8DBFF);
  static const Color primaryColorLight = Color(0xFFE8F3FF);

  // Figma Secondary Colors (メインカラー)
  static const Color secondaryColor = Color(0xFF92C9FF);
  static const Color secondaryColorDark = Color(0xFF7DB8FF);
  static const Color secondaryColorLight = Color(0xFFA7D4FF);

  // Basic Colors
  static const Color neutralColor = Color(0xFFFFFFFF);
  static const Color grayColor = Color(0xFFD9D9D9);
  static const Color grayColorDark = Color(0xFFC4C4C4);
  static const Color grayColorLight = Color(0xFFEEEEEE);

  // Status Colors
  static const Color successColor = Color(0xFFB5FCB0);
  static const Color errorColor = Color(0xFFFF9B9B);

  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textMuted = Color(0xFF999999);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Background Colors
  static const Color backgroundPrimary = neutralColor;
  static const Color backgroundSecondary = primaryColorLight;
  static const Color backgroundTertiary = grayColorLight;
  static const Color backgroundMuted = grayColorLight;

  // Border Colors
  static const Color borderColor = grayColor;
  static const Color borderColorHover = grayColorDark;
  static const Color borderColorFocus = secondaryColor;

  // ===== タイポグラフィ =====
  static const String fontFamily = 'ABeeZee';
  
  // Font Sizes
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;
  static const double fontSize3xl = 30;
  static const double fontSize4xl = 36;

  // Line Heights
  static const double lineHeightBase = 1.0;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // ===== スペーシング =====
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2xl = 48;
  static const double spacing3xl = 64;

  // ===== ボーダーラディウス =====
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // ===== シャドウ =====
  static final BoxShadow shadowSm = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    offset: const Offset(0, 1),
    blurRadius: 2,
  );

  static final BoxShadow shadowMd = BoxShadow(
    color: Colors.black.withOpacity(0.07),
    offset: const Offset(0, 4),
    blurRadius: 6,
  );

  static final BoxShadow shadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    offset: const Offset(0, 10),
    blurRadius: 15,
  );

  // ===== テキストスタイル =====
  static const TextStyle headingXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize3xl,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: lineHeightBase,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize2xl,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: lineHeightBase,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXl,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: lineHeightBase,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLg,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: lineHeightNormal,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: lineHeightNormal,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSm,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: lineHeightNormal,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: lineHeightNormal,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMd,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: lineHeightBase,
  );

  // ===== コンポーネントスタイル =====
  
  // Primary Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: textInverse,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLg,
      vertical: spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusFull),
    ),
    textStyle: button,
    elevation: 0,
  );

  // Secondary Button Style
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLg,
      vertical: spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusFull),
    ),
    textStyle: button,
    elevation: 0,
  );

  // Text Field Decoration
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: bodyMd.copyWith(color: textMuted),
      labelStyle: bodySm.copyWith(color: textSecondary),
      filled: true,
      fillColor: backgroundPrimary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderColorFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: backgroundPrimary,
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: [shadowMd],
  );

  // Message Container Decoration
  static BoxDecoration messageContainerDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: borderColor, width: 1),
  );

  // Success Container Decoration
  static BoxDecoration successContainerDecoration = BoxDecoration(
    color: successColor,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: successColor, width: 1),
  );

  // ===== テーマデータ =====
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundMuted,
    colorScheme: const ColorScheme.light(
      primary: secondaryColor,
      secondary: primaryColor,
      surface: backgroundPrimary,
      error: errorColor,
      onPrimary: textInverse,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textInverse,
    ),
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundPrimary,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headingMd,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundPrimary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderColor),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: spacingMd,
    ),
  );
}