import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('GlassSegmentedControl 切换分段', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) => GlassSegmentedControl(
                segments: const [
                  GlassSegment(label: '教师'),
                  GlassSegment(label: '学生'),
                ],
                selectedIndex: selected,
                onSegmentSelected: (index) => setState(() => selected = index),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('教师'), findsOneWidget);
    expect(find.text('学生'), findsOneWidget);
    await tester.tap(find.text('学生'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('GlassContainer.card solid 渲染为实色卡片', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: GlassContainer.card(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: Text('卡片'),
          ),
        ),
      ),
    );

    expect(find.text('卡片'), findsOneWidget);
  });
}


