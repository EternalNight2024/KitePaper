import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LiquidGlassWidgets.initialize();
  } catch (error) {
    debugPrint('[KitePaper] 玻璃着色器预热跳过：$error');
  }
  await store.load();

  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      respectSystemAccessibility: true,
      brightnessResolver: (context) => Theme.of(context).brightness,
      theme: const GlassThemeData(),
      child: const KitePaperApp(),
    ),
  );
}
