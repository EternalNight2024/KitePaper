import 'package:flutter/material.dart';

import 'features/shell.dart';
import 'theme/app_theme.dart';

class KitePaperApp extends StatelessWidget {
  const KitePaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '纸鸢 KitePaper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
