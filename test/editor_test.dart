import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kitepaper/core/store.dart';
import 'package:kitepaper/features/question_editor_page.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        theme: const GlassThemeData.ios27(),
        child: const CupertinoApp(home: QuestionEditorPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('默认提供四个选项与添加按钮', (tester) async {
    await pumpEditor(tester);
    expect(find.text('选项 A 内容'), findsOneWidget);
    expect(find.textContaining('添加选项 · 4/8'), findsOneWidget);
  });

  testWidgets('点击添加/删除选项会更新数量提示', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.textContaining('添加选项 · 4/8'));
    await tester.pumpAndSettle();
    expect(find.textContaining('添加选项 · 5/8'), findsOneWidget);

    // 删除第一个选项后回到 4 个。
    await tester.tap(find.byIcon(CupertinoIcons.minus_circle).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('添加选项 · 4/8'), findsOneWidget);
  });

  testWidgets('判断题预设正确/错误选项且无添加按钮', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.text('判断题'));
    await tester.pumpAndSettle();
    expect(find.text('正确'), findsWidgets);
    expect(find.text('错误'), findsWidgets);
    expect(find.textContaining('添加选项'), findsNothing);
  });
}
