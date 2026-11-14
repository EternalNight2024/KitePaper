import 'package:material_ui/material_ui.dart';

import 'features/home/home_page.dart';
import 'theme/app_theme.dart';

class KitePaperApp extends StatelessWidget {
  const KitePaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '纸鸢 KitePaper',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
