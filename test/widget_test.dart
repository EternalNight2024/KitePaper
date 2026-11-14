import 'package:flutter_test/flutter_test.dart';

import 'package:kitepaper/app.dart';

void main() {
  testWidgets('首页展示中英文项目名称', (WidgetTester tester) async {
    await tester.pumpWidget(const KitePaperApp());

    expect(find.text('纸鸢'), findsOneWidget);
    expect(find.text('KitePaper'), findsOneWidget);
  });
}
