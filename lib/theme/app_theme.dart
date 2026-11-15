import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Apple 风格主题：系统字体 + 尺寸相关的字距/行高（见 apple-design §15）。
abstract final class AppTheme {
  static const accent = Color(0xFF0A84FF);
  static const accentDeep = Color(0xFF0060DF);
  static const destructive = Color(0xFFFF453A);


  static TextTheme _texts(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E);
    final secondary = dark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73);
    final tertiary = dark ? const Color(0xFF8A8A8E) : const Color(0xFF8E8E93);

    TextStyle style(
      double size,
      double height,
      double tracking,
      FontWeight weight,
      Color color,
    ) =>
        TextStyle(
          fontSize: size,
          height: height,
          letterSpacing: tracking,
          fontWeight: weight,
          color: color,
        );

    return TextTheme(
      // 大标题：负字距 + 紧行高
      displaySmall: style(34, 1.12, -0.9, FontWeight.w700, primary),
      headlineSmall: style(24, 1.18, -0.6, FontWeight.w700, primary),
      titleMedium: style(17, 1.25, -0.25, FontWeight.w600, primary),
      titleSmall: style(15, 1.3, -0.15, FontWeight.w600, primary),
      bodyMedium: style(15, 1.42, 0, FontWeight.w400, primary),
      bodySmall: style(13, 1.36, 0.1, FontWeight.w400, secondary),
      labelSmall: style(11, 1.2, 0.4, FontWeight.w600, tertiary),
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
      colorScheme: scheme.copyWith(primary: accent, error: destructive),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _texts(brightness),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // 空间一致性：进入/退出走同一条路径（apple-design §7）
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
}
