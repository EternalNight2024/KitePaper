import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const _seedColor = Color(0xFF2F6FED);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}
