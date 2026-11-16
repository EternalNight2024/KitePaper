import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/glass_motion.dart';
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
      builder: (context, child) {
        // liquid_glass_widgets 是 Material-free 的：其内部大量组件基于
        // CupertinoTextField / CupertinoTheme。MaterialApp 下必须补上
        // 1) 透明 Material 祖先，2) 与 Material 主题同步的 CupertinoTheme，
        // 否则输入框、列表文字、对话框在暗色模式下不会跟随主题。
        final brightness = Theme.of(context).brightness;
        return NativeGlassMotion(
          child: GlassNavigationShell(
            child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: brightness,
              primaryColor: AppTheme.accent,
              scaffoldBackgroundColor: Colors.transparent,
              textTheme: AppTheme.cupertinoText(brightness),
            ),
              child: Material(
                type: MaterialType.transparency,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: const AppShell(),
    );
  }
}
