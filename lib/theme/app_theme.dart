import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/models.dart';

/// 纯净灰白主题：与 ios27 玻璃材质搭配的中性色板。
abstract final class AppTheme {
  /// 可选的自定义字体族；留空则使用平台系统字体。
  /// 截图/黄金测试会注入含中文字形的字体以便人工核对视觉效果。
  static String? fontFamilyOverride;

  /// 主强调色：石墨灰。两种身份共用灰白骨架，仅用低饱和冷/暖色点缀。
  static const accent = Color(0xFF4A4A4F);
  static const accentDeep = Color(0xFF2E2E33);
  static const destructive = Color(0xFFB26A6A);
  static const success = Color(0xFF4F8A6B);
  static const warning = Color(0xFFB08848);

  /// 身份色：教师偏冷靛蓝，学生偏青绿，用于模式标识而不改变灰白基调。
  static const teacher = Color(0xFF5B6BA8);
  static const student = Color(0xFF3F8C86);

  /// 题型色：在灰白列表里用一枚小色点区分为五种题型。
  static const typeSingle = Color(0xFF5B6BA8);
  static const typeMultiple = Color(0xFF8A6AAA);
  static const typeTrueFalse = Color(0xFF4F8A6B);
  static const typeFillBlank = Color(0xFFB08848);
  static const typeEssay = Color(0xFFB2687A);

  static Color typeColor(QuestionType type) => switch (type) {
        QuestionType.single => typeSingle,
        QuestionType.multiple => typeMultiple,
        QuestionType.trueFalse => typeTrueFalse,
        QuestionType.fillBlank => typeFillBlank,
        QuestionType.essay => typeEssay,
      };

  static Color modeColor(AppMode mode) =>
      mode == AppMode.teacher ? teacher : student;

  static TextTheme _texts(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E);
    final secondary = dark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73);
    final tertiary = dark ? const Color(0xFF8A8A8E) : const Color(0xFF8E8E93);

    TextStyle style(double size, double height, double tracking,
            FontWeight weight, Color color) =>
        TextStyle(
          fontSize: size,
          height: height,
          letterSpacing: tracking,
          fontWeight: weight,
          color: color,
        );

    return TextTheme(
      displaySmall: style(34, 1.12, -0.9, FontWeight.w700, primary),
      headlineSmall: style(24, 1.18, -0.6, FontWeight.w700, primary),
      titleMedium: style(17, 1.25, -0.25, FontWeight.w600, primary),
      titleSmall: style(15, 1.3, -0.15, FontWeight.w600, primary),
      bodyMedium: style(15, 1.42, 0, FontWeight.w400, primary),
      bodySmall: style(13, 1.36, 0.1, FontWeight.w400, secondary),
      labelSmall: style(11, 1.2, 0.4, FontWeight.w600, tertiary),
    );
  }

  /// Cupertino 文本主题：与 Material 保持一致，供玻璃库内的 Cupertino 组件使用。
  static CupertinoTextThemeData cupertinoText(Brightness brightness) {
    final texts = _texts(brightness);
    return CupertinoTextThemeData(
      primaryColor: accent,
      textStyle: texts.bodyMedium!.copyWith(fontFamily: fontFamilyOverride),
      actionTextStyle: texts.titleSmall!.copyWith(color: accent),
      navTitleTextStyle: texts.titleMedium!,
      navLargeTitleTextStyle: texts.displaySmall!,
      tabLabelTextStyle: texts.labelSmall!,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamilyOverride,
      colorScheme: scheme.copyWith(primary: accent, error: destructive),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _texts(brightness),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const GlassPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
}
