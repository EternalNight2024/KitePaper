import 'package:material_ui/material_ui.dart';

import 'features/shell.dart';
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
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
