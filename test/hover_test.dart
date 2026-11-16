import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:kitepaper/core/glass_motion.dart';

const _probeKey = Key('probe');

/// 从探针 widget 读取最近的 GlassThemeData（即 GlassMotionScope 注入的那层）。
double _angleOf(WidgetTester tester) => GlassThemeData.of(tester.element(_find))
    .light
    .settings
    ?.lightAngle ?? 0;

Finder get _find => find.byKey(_probeKey);

Widget _wrap(Widget probe) => MaterialApp(
      home: GlassTheme(
        data: const GlassThemeData.ios27(),
        child: NativeGlassMotion(child: probe),
      ),
    );

void main() {
  testWidgets('桌面鼠标移动驱动原生光源角度', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(
      const Center(child: SizedBox(key: _probeKey, width: 400, height: 200)),
    ));

    final start = _angleOf(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(const Offset(1150, 400));
    await tester.pumpAndSettle();
    final right = _angleOf(tester);
    expect(right, greaterThan(start));

    await gesture.moveTo(const Offset(80, 400));
    await tester.pumpAndSettle();
    final left = _angleOf(tester);
    expect(left, lessThan(right));
    // x=80 / 1280 → (0.25 + 0.0625)π
    expect(left, closeTo(0.3125 * pi, 0.05));
  });

  testWidgets('窄屏不驱动光源角度', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(
      const Center(child: SizedBox(key: _probeKey, width: 200, height: 100)),
    ));

    final before = _angleOf(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: const Offset(300, 400));
    await tester.pumpAndSettle();
    expect(_angleOf(tester), before);
  });
}
