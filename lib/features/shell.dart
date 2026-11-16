import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/app_background.dart';
import '../core/layout.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme/app_theme.dart';
import 'bank_page.dart';
import 'builder_page.dart';
import 'guide_page.dart';
import 'papers_page.dart';
import 'results_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _TabSpec {
  const _TabSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// 页面构造器：窄屏传入大标题控制器，宽屏传 null。
  final Widget Function(GlassLargeTitleController?) page;
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  Color _accent = AppTheme.teacher;
  final Map<String, GlassLargeTitleController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  GlassLargeTitleController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, GlassLargeTitleController.new);

  List<_TabSpec> _tabs(AppMode mode) => mode == AppMode.teacher
      ? [
          _TabSpec(
            title: '题库',
            subtitle: '本地题目与导入',
            icon: CupertinoIcons.book,
            page: (c) => BankPage(controller: c),
          ),
          _TabSpec(
            title: '组卷',
            subtitle: '挑选题目生成试卷',
            icon: CupertinoIcons.square_stack_3d_up,
            page: (c) => BuilderPage(controller: c, onCreated: () => _select(2)),
          ),
          _TabSpec(
            title: '试卷',
            subtitle: '导出 QTI 分享',
            icon: CupertinoIcons.doc_text,
            page: (c) => PapersPage(mode: AppMode.teacher, controller: c),
          ),
          _TabSpec(
            title: '指引',
            subtitle: '教程与在线功能',
            icon: CupertinoIcons.lightbulb,
            page: (c) => GuidePage(mode: AppMode.teacher, controller: c),
          ),
        ]
      : [
          _TabSpec(
            title: '练习',
            subtitle: '导入试卷并刷题',
            icon: CupertinoIcons.pencil,
            page: (c) => PapersPage(mode: AppMode.student, controller: c),
          ),
          _TabSpec(
            title: '成绩',
            subtitle: '成绩与错题本',
            icon: CupertinoIcons.chart_bar,
            page: (c) => ResultsPage(controller: c),
          ),
          _TabSpec(
            title: '指引',
            subtitle: '教程与在线功能',
            icon: CupertinoIcons.lightbulb,
            page: (c) => GuidePage(mode: AppMode.student, controller: c),
          ),
        ];

  void _select(int index) => setState(() => _index = index);

  void _setMode(int index) {
    final mode = index == 0 ? AppMode.teacher : AppMode.student;
    if (mode == store.mode) return;
    store.setMode(mode);
    setState(() => _index = 0);
  }

  /// 模式切换控件：教师 / 学生。
  Widget _modeSwitch({bool compact = false, bool withIcons = false}) =>
      GlassSegmentedControl(
        segments: [
          GlassSegment(
            label: '教师',
            icon: withIcons
                ? const Icon(CupertinoIcons.person_crop_square, size: 15)
                : null,
          ),
          GlassSegment(
            label: '学生',
            icon: withIcons ? const Icon(CupertinoIcons.book, size: 15) : null,
          ),
        ],
        selectedIndex: store.mode == AppMode.teacher ? 0 : 1,
        onSegmentSelected: _setMode,
        height: compact ? 32 : 36,
        indicatorColor: _accent,
        // 库内部按 fontSize 构造标签样式（不带字体族），这里显式补上，
        // 以便统一使用主题字体。
        selectedTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamilyOverride,
        ),
        unselectedTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: AppTheme.fontFamilyOverride,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tabs = _tabs(store.mode);
        final index = _index.clamp(0, tabs.length - 1);
        _accent = AppTheme.modeColor(store.mode);
        final wide = MediaQuery.sizeOf(context).width >= kLargeScreenMinWidth;
        // 仅窄屏使用大标题；宽屏侧边栏布局不需要滚动折叠标题。
        final controller = wide
            ? null
            : _controllerFor('${store.mode.code}-$index-${tabs[index].title}');

        return GlassScaffold(
          background: const AppBackground(),
          backgroundColor: appBackgroundColor(Theme.of(context).brightness),
          statusBarStyle: GlassStatusBarStyle.auto,
          appBar: wide
              ? null
              : GlassAppBar(
                  centerTitle: false,
                  title: Text(
                    tabs[index].title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  largeTitleController: controller,
                  actions: [
                    // AppBar 的 actions 槽位宽度不受限，GlassSegmentedControl
                    // 内部使用 Expanded 无法在此布局，故窄屏改用下拉菜单。
                    GlassPullDownButton(
                      buttonWidth: 38,
                      buttonHeight: 32,
                      buttonShape:
                          const LiquidRoundedSuperellipse(borderRadius: 11),
                      icon: Icon(
                        store.mode == AppMode.teacher
                            ? CupertinoIcons.person_crop_square_fill
                            : CupertinoIcons.book_fill,
                        size: 17,
                      ),
                      semanticLabel: '切换身份',
                      menuSemanticLabel: '选择身份',
                      items: [
                        GlassMenuItem(
                          title: '教师模式',
                          icon: const Icon(CupertinoIcons.person_crop_square),
                          isSelected: store.mode == AppMode.teacher,
                          onTap: () => _setMode(0),
                        ),
                        GlassMenuItem(
                          title: '学生模式',
                          icon: const Icon(CupertinoIcons.book),
                          isSelected: store.mode == AppMode.student,
                          onTap: () => _setMode(1),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
          body: _body(tabs, index, wide),
          bottomBar: wide
              ? null
              : GlassTabBar.bottom(
                  tabs: [
                    for (final tab in tabs)
                      GlassTab(icon: Icon(tab.icon), label: tab.title),
                  ],
                  selectedIndex: index,
                  onTabSelected: _select,
                  selectedIconColor: AppTheme.accent,
                  selectedLabelColor: AppTheme.accent,
                ),
        );
      },
    );
  }

  Widget _body(List<_TabSpec> tabs, int index, bool wide) {
    final pages = [
      for (var i = 0; i < tabs.length; i++)
        tabs[i].page(wide
            ? null
            : _controllerFor('${store.mode.code}-$i-${tabs[i].title}')),
    ];

    if (!wide) {
      return IndexedStack(index: index, children: pages);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 252, child: _sidebar(tabs, index)),
        const SizedBox(width: 20),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KITEPAPER',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(letterSpacing: 1.8),
                              ),
                              const SizedBox(height: 2),
                              Text(tabs[index].subtitle,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        // Row 的非 flex 子项会拿到无界宽度，分段控件内部
                        // 使用 Expanded，必须显式约束宽度。
                                        SizedBox(width: 132, child: _modeSwitch()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(index: index, children: pages),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _sidebar(List<_TabSpec> tabs, int index) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_accent, AppTheme.accentDeep],
                      ),
                    ),
                    child: const Icon(CupertinoIcons.paperplane_fill,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 11),
                  Text('纸鸢', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            for (var i = 0; i < tabs.length; i++)
              GlassButton.custom(
                onTap: () => _select(i),
                height: 44,
                style: GlassButtonStyle.transparent,
                shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                glowColor: i == index
                    ? AppTheme.accent
                    : theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(tabs[i].icon,
                          size: 20,
                          color: i == index ? _accent : null),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tabs[i].title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: i == index ? _accent : null,
                            fontWeight: i == index
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (i == index)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Text('离线 · 数据仅存本机',
                  style: theme.textTheme.labelSmall),
            ),
          ],
        ),
      ),
    );
  }
}
