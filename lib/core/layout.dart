import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 页面布局辅助（玻璃效果统一由 liquid_glass_widgets 提供）。
const pagePadding = EdgeInsets.fromLTRB(20, 10, 20, 28);
const desktopPagePadding = EdgeInsets.fromLTRB(24, 12, 24, 32);
const double kContentMaxWidth = 920;
const double kLargeScreenMinWidth = 700;

/// `GlassTabBar.bottom` 的实际占用高度：barHeight 64 + verticalPadding 20×2。
const double kFloatingTabBarHeight = 104;

/// 浮动底栏 + 安全区所需的底部留白。
double bottomSafeInset(BuildContext context) =>
    kFloatingTabBarHeight + MediaQuery.paddingOf(context).bottom;

/// `GlassAppBar` 的工具栏高度（不含状态栏）。
const double kAppBarToolbarHeight = 44.0;

/// `GlassScaffold` 不会为 body 预留导航栏高度（body 铺满并由边缘渐隐处理），
/// 因此页面需自行补足「状态栏 + 导航栏」的顶部留白。
double appBarSafeTop(BuildContext context) =>
    MediaQuery.paddingOf(context).top + kAppBarToolbarHeight;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kLargeScreenMinWidth;

EdgeInsetsGeometry adaptivePagePadding(BuildContext context) =>
    isWideScreen(context) ? desktopPagePadding : pagePadding;

Widget responsiveContent(BuildContext context, Widget child) {
  if (!isWideScreen(context)) return child;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
      // 需要显式撑满，否则 Column 会按子项内容收缩宽度。
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// 分值展示：整数不带小数点。
String formatScore(double score) => score == score.roundToDouble()
    ? score.toStringAsFixed(0)
    : score.toStringAsFixed(1);

/// 页面正文容器。
///
/// 传入 [controller] 时使用 `CustomScrollView` + `GlassLargeTitle`（窄屏 iOS
/// 大标题折叠）；不传时退化为普通列表（宽屏侧边栏布局）。
class GlassPageBody extends StatelessWidget {
  const GlassPageBody({
    super.key,
    required this.children,
    this.controller,
    this.title,
    this.leading,
  });

  final List<Widget> children;
  final GlassLargeTitleController? controller;
  final String? title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bottom = bottomSafeInset(context);
    final largeTitle = controller;

    if (largeTitle == null) {
      return ListView(
        padding: pagePadding.copyWith(bottom: bottom),
        children: children,
      );
    }

    return CustomScrollView(
      controller: largeTitle.scrollController,
      slivers: [
        // 让大标题从导航栏下方开始，滚动时再滑入导航栏之下。
        SliverToBoxAdapter(child: SizedBox(height: appBarSafeTop(context))),
        GlassLargeTitle(
          text: title ?? '',
          controller: largeTitle,
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
          trailing: leading,
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
          sliver: SliverList.list(children: children),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottom)),
      ],
    );
  }
}

Widget sectionHeader(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

Widget mutedText(BuildContext context, String text, {int maxLines = 3}) => Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
