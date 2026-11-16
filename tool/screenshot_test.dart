// 视觉回归截图工具：用真实字体渲染界面，输出 PNG 供人工检查。
// 运行： flutter test tool/screenshot_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kitepaper/app.dart';
import 'package:kitepaper/core/models.dart';
import 'package:kitepaper/features/exam_page.dart';
import 'package:kitepaper/features/question_editor_page.dart';
import 'package:kitepaper/core/models.dart';
import 'package:kitepaper/theme/app_theme.dart';
import 'package:kitepaper/core/store.dart';

const _fontPaths = {
  'Roboto': [
    '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
    '/opt/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
  ],
  'NotoSansSC': ['/tmp/fonts/NotoSansSC.ttf'],
  'CupertinoIcons': [
    '/root/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf',
  ],
  'packages/cupertino_icons/CupertinoIcons': [
    '/root/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf',
  ],
  'MaterialIcons': [
    '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ],
};

Future<void> _loadFonts() async {
  for (final entry in _fontPaths.entries) {
    final loader = FontLoader(entry.key);
    var loaded = false;
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loaded = true;
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    }
    if (loaded) await loader.load();
  }
  AppTheme.fontFamilyOverride = 'NotoSansSC';
}

Future<void> _pump(WidgetTester tester, Size size, String name,
    {Brightness brightness = Brightness.light}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: const GlassThemeData.ios27(),
      child: const KitePaperApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
    await store.load();
  });

  testWidgets('mobile-teacher', (tester) async {
    await _pump(tester, const Size(390, 844), 'mobile-teacher');
  });

  testWidgets('mobile-student', (tester) async {
    await store.setMode(AppMode.student);
    await _pump(tester, const Size(390, 844), 'mobile-student');
  });

  testWidgets('desktop-teacher', (tester) async {
    await store.setMode(AppMode.teacher);
    await _pump(tester, const Size(1280, 860), 'desktop-teacher');
  });

  testWidgets('mobile-dark', (tester) async {
    await store.setMode(AppMode.teacher);
    await _pump(tester, const Size(390, 844), 'mobile-dark',
        brightness: Brightness.dark);
  });

  testWidgets('desktop-student', (tester) async {
    await store.setMode(AppMode.student);
    await _pump(tester, const Size(1280, 860), 'desktop-student');
  });

  testWidgets('mobile-exam', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final paper = store.papers.first;
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        adaptiveQuality: true,
        brightnessResolver: Theme.maybeBrightnessOf,
        theme: const GlassThemeData.ios27(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: AppTheme.fontFamilyOverride,
          ),
          home: ExamPage(paper: paper),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/mobile-exam.png'),
    );
  });

  testWidgets('mobile-editor', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        adaptiveQuality: true,
        brightnessResolver: Theme.maybeBrightnessOf,
        theme: const GlassThemeData.ios27(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: AppTheme.fontFamilyOverride,
          ),
          home: const QuestionEditorPage(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/mobile-editor.png'),
    );
  });
}
