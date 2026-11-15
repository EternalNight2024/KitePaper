import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../theme/app_theme.dart';
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
  static const _subtitles = ['本地题目与导入', '挑选题目生成试卷', '刷题与分享', '成绩与错题本'];
  static const _icons = [
    Icons.library_books_outlined,
    Icons.playlist_add_rounded,
    Icons.article_outlined,
    Icons.insights_outlined,
  ];

  List<Widget> get _pages => [
        const BankPage(),
        BuilderPage(onCreated: () => setState(() => _index = 2)),
        const PapersPage(),
        const ResultsPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= kLargeScreenMinWidth) {
              return _desktopLayout();
            }
            return _mobileLayout();
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 移动端

  Widget _mobileLayout() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Column(
          children: [
            _largeTitle(),
            Expanded(
              child: IndexedStack(index: _index, children: _pages),
            ),
          ],
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 14 + bottomInset,
          child: GlassPanel(
            heavy: true,
            hoverable: false,
            radius: 28,
            sigma: 30,
            padding: const EdgeInsets.all(7),
            child: Row(
              children: [
                for (var i = 0; i < _titles.length; i++)
                  Expanded(child: _tabItem(i)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabItem(int i) {
    final selected = _index == i;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final idle = dark
        ? Colors.white.withValues(alpha: 0.66)
        : const Color(0xFF6E6E73);

    return GlassNavItem(
      selected: selected,
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      onTap: () => setState(() => _index = i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[i], size: 20, color: selected ? AppTheme.accent : idle),
          const SizedBox(height: 3),
          Text(
            _titles[i],
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.2,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.accent : idle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeTitle() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KITEPAPER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(_titles[_index], style: theme.textTheme.displaySmall),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.auto_awesome_outlined,
            label: '纸鸢',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 桌面端

  Widget _desktopLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 264, child: _sidebar()),
          const SizedBox(width: 22),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _desktopHeader(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: IndexedStack(index: _index, children: _pages),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return GlassPanel(
      heavy: true,
      hoverable: false,
      radius: 26,
      sigma: 30,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: squircle(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.accent, Color(0xFF5E5CE6)],
                    ),
                  ),
                  child: const SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(Icons.air, size: 17, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '纸鸢',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _titles.length; i++) _sideItem(i),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: Text(
              '离线 · 数据仅存本机',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.6,
                color: dark
                    ? Colors.white.withValues(alpha: 0.45)
                    : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(int i) {
    final selected = _index == i;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GlassNavItem(
        selected: selected,
        radius: 14,
        onTap: () => setState(() => _index = i),
        child: Row(
          children: [
            Icon(
              _icons[i],
              size: 19,
              color: selected
                  ? AppTheme.accent
                  : (dark
                      ? Colors.white.withValues(alpha: 0.72)
                      : const Color(0xFF6E6E73)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                _titles[i],
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected
                      ? (dark ? Colors.white : const Color(0xFF1C1C1E))
                      : (dark
                          ? Colors.white.withValues(alpha: 0.80)
                          : const Color(0xFF3A3A3C)),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _desktopHeader() {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KITEPAPER',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(_titles[_index], style: theme.textTheme.displaySmall),
            ],
          ),
        ),
        Text(_subtitles[_index], style: theme.textTheme.bodySmall),
      ],
    );
  }
}
