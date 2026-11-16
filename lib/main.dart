import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app.dart';
import 'core/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await store.load();
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      respectSystemAccessibility: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: const GlassThemeData.ios27(
        // 原生按压物理：iOS 26 果冻式缩放/拉伸，全站统一。
        interaction: GlassInteractionSettings(
          stretch: 0.45,
          interactionScale: 1.06,
        ),
      ),
      child: const KitePaperApp(),
    ),
  );
}
