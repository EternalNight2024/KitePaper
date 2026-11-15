import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kitepaper/core/ui.dart';

void main() {
  testWidgets('导航项悬浮时出现高亮背景', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: GlassNavItem(
                selected: false,
                child: const Text('组卷'),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    ShapeDecoration decorationOf() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(GlassNavItem),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as ShapeDecoration;
    }

    expect(decorationOf().color, Colors.transparent);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();

    await gesture.moveTo(tester.getCenter(find.text('组卷')));
    await tester.pumpAndSettle();

    expect(decorationOf().color, isNot(Colors.transparent));
    expect(decorationOf().color!.a, greaterThan(0));

    await gesture.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();

    expect(decorationOf().color, Colors.transparent);
  });

  testWidgets('玻璃面板使用超椭圆圆角', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassPanel(child: Text('卡片')),
        ),
      ),
    );

    final clip = tester.widget<ClipPath>(
      find.descendant(
        of: find.byType(GlassPanel),
        matching: find.byType(ClipPath),
      ),
    );
    expect(clip.clipper, isA<SquircleClipper>());

    final clipper = clip.clipper! as SquircleClipper;
    expect(clipper.border, isA<RoundedSuperellipseBorder>());
  });
}
