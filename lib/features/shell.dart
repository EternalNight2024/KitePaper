import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../core/ui.dart';
import 'bank_page.dart';
import 'builder_page.dart';
import 'papers_page.dart';
import 'results_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['题库', '组卷', '试卷', '成绩'];
  static const _tabs = [
    GlassTab(icon: Icon(Icons.library_books), label: '题库'),
    GlassTab(icon: Icon(Icons.playlist_add), label: '组卷'),
    GlassTab(icon: Icon(Icons.description), label: '试卷'),
    GlassTab(icon: Icon(Icons.assessment), label: '成绩'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: glassBackground(Theme.of(context).brightness),
      appBar: GlassAppBar(title: Text('纸鸢 · ${_titles[_index]}')),
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _index,
        onTabSelected: (index) => setState(() => _index = index),
        tabs: _tabs,
      ),
      body: IndexedStack(
        index: _index,
        children: [
          const BankPage(),
          BuilderPage(onCreated: () => setState(() => _index = 2)),
          const PapersPage(),
          const ResultsPage(),
        ],
      ),
    );
  }
}
