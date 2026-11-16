import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 移动端底部浮层导航高度预留。
const pagePadding = EdgeInsets.fromLTRB(18, 8, 18, 128);

const double kGlassRadius = 22;

/// 桌面端内容最大宽度（可读性）。
const double kContentMaxWidth = 920;

const double kLargeScreenMinWidth = 700;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kLargeScreenMinWidth;

bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

bool highContrast(BuildContext context) => MediaQuery.highContrastOf(context);

/// 超椭圆（iOS 连续圆角）描边形状。
RoundedSuperellipseBorder squircle(
  double radius, {
  BorderSide side = BorderSide.none,
}) =>
    RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side,
    );

/// 用超椭圆形状裁剪（用于背景模糊层）。
class SquircleClipper extends CustomClipper<Path> {
  const SquircleClipper(this.border);

  final ShapeBorder border;

  @override
  Path getClip(Size size) => border.getOuterPath(Offset.zero & size);

  @override
  bool shouldReclip(SquircleClipper oldClipper) => oldClipper.border != border;
}

/// 静态渐变 + 光斑背景（不做低频循环动画）。
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0B1220), Color(0xFF17122B), Color(0xFF0A1F26)]
              : const [
                  Color(0xFFF9FBFF),
                  Color(0xFFFCF9FF),
                  Color(0xFFFFFAF7),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            left: -90,
            child: _orb(
              dark ? const Color(0x33FF8A5B) : const Color(0x40FFC7AE),
              360,
            ),
          ),
          Positioned(
            top: 70,
            right: -120,
            child: _orb(
              dark ? const Color(0x308A7BFF) : const Color(0x3DA6C0FF),
              340,
            ),
          ),
          Positioned(
            bottom: -130,
            left: 20,
            child: _orb(
              dark ? const Color(0x302ED7C8) : const Color(0x3D8FE6DC),
              320,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _orb(Color color, double size) => SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}

/// 液态玻璃材质：超椭圆圆角 + 模糊 + 近白半透明填充 + 高光描边 + 投影。
///
/// 鼠标悬浮时轻微上浮并加深投影（触屏不受影响）。
class GlassPanel extends StatefulWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = kGlassRadius,
    this.sigma = 24,
    this.heavy = false,
    this.margin,
    this.hoverable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double sigma;
  final bool heavy;
  final EdgeInsetsGeometry? margin;
  final bool hoverable;

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final solid = highContrast(context);
    final animate = !reduceMotion(context);
    final hover = widget.hoverable && animate && _hover;

    final borderColor = solid
        ? (dark ? Colors.white60 : Colors.black26)
        : (dark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.96));

    // 更洁白的材质：浅色模式接近白纸，深色模式为轻薄雾面
    final alpha = widget.heavy
        ? (dark ? 0.16 : 0.82)
        : (dark ? 0.11 : 0.70);

    final outer = squircle(
      widget.radius,
      side: BorderSide(color: borderColor, width: 0.9),
    );
    final inner = squircle(widget.radius);

    final fill = DecoratedBox(
      decoration: ShapeDecoration(
        shape: inner,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: solid ? 0.98 : alpha),
            Colors.white.withValues(alpha: solid ? 0.95 : alpha * 0.84),
          ],
        ),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    return MouseRegion(
      cursor: widget.hoverable ? SystemMouseCursors.basic : MouseCursor.defer,
      onEnter: widget.hoverable && animate
          ? (_) => setState(() => _hover = true)
          : null,
      onExit: widget.hoverable && animate
          ? (_) => setState(() => _hover = false)
          : null,
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: AnimatedContainer(
          duration: Duration(milliseconds: animate ? 200 : 0),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, hover ? -2 : 0, 0),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: outer,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: hover
                        ? (dark ? 0.14 : 0.05)
                        : (dark ? 0.09 : 0.03),
                  ),
                  blurRadius: hover ? 20 : 12,
                  offset: Offset(0, hover ? 6 : 4),
                ),
              ],
            ),
            child: ClipPath(
              clipper: SquircleClipper(inner),
              child: solid
                  ? fill
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.sigma,
                        sigmaY: widget.sigma,
                      ),
                      child: fill,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 按下即反馈、悬浮放大、指针变手型。
class GlassTappable extends StatefulWidget {
  const GlassTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
    this.hoverScale = 1.02,
    this.behavior = HitTestBehavior.opaque,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;
  final double hoverScale;
  final HitTestBehavior behavior;

  @override
  State<GlassTappable> createState() => _GlassTappableState();
}

class _GlassTappableState extends State<GlassTappable> {
  bool _pressed = false;
  bool _hover = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHover(bool value) {
    if (_hover == value) return;
    setState(() => _hover = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final animate = !reduceMotion(context);
    final double scale;
    if (!enabled) {
      scale = 1;
    } else if (_pressed) {
      scale = widget.scale;
    } else if (_hover && animate) {
      scale = widget.hoverScale;
    } else {
      scale = 1;
    }

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => _setHover(true) : null,
      onExit: enabled ? (_) => _setHover(false) : null,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: animate ? 130 : 0),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 导航项：悬浮高亮 + 选中态（超椭圆圆角）。
class GlassNavItem extends StatefulWidget {
  const GlassNavItem({
    super.key,
    required this.child,
    required this.selected,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    this.onTap,
  });

  final Widget child;
  final bool selected;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<GlassNavItem> createState() => _GlassNavItemState();
}

class _GlassNavItemState extends State<GlassNavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final animate = !reduceMotion(context);
    final radius = BorderRadius.circular(widget.radius);

    Color background() {
      if (widget.selected) {
        return AppTheme.accent.withValues(alpha: dark ? 0.26 : 0.12);
      }
      if (_hover && animate) {
        return (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.10 : 0.08);
      }
      return Colors.transparent;
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: animate ? 170 : 0),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(borderRadius: radius),
            color: background(),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 主/次/危险三种按钮。
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.destructive = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool destructive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = destructive ? AppTheme.destructive : AppTheme.accent;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 13);
    final fontSize = compact ? 13.5 : 15.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: compact ? 15 : 17,
            color: primary || destructive
                ? Colors.white
                : (dark ? Colors.white : AppTheme.accent),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.0,
            letterSpacing: 0,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.w600,
            color: primary || destructive
                ? Colors.white
                : (dark ? Colors.white : const Color(0xFF1C1C1E)),
          ),
        ),
      ],
    );

    final radius = compact ? 12.0 : 14.0;

    if (primary || destructive) {
      final shape = squircle(radius);
      return GlassTappable(
        onTap: onPressed,
        hoverScale: 1.03,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            shadows: [
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipPath(
            clipper: SquircleClipper(shape),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: shape,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent,
                    Color.lerp(accent, Colors.black, 0.18) ?? accent,
                  ],
                ),
              ),
              child: Padding(padding: padding, child: content),
            ),
          ),
        ),
      );
    }

    return GlassTappable(
      onTap: onPressed,
      hoverScale: 1.03,
      child: GlassPanel(
        padding: padding,
        radius: radius,
        sigma: 18,
        hoverable: false,
        child: content,
      ),
    );
  }
}

/// 圆形/胶囊玻璃图标按钮。
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tint,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF1C1C1E));
    return GlassTappable(
      onTap: onPressed,
      hoverScale: 1.06,
      child: GlassPanel(
        padding: const EdgeInsets.all(10),
        radius: 999,
        sigma: 16,
        hoverable: false,
        child: Icon(icon, size: 18, color: color, semanticLabel: label),
      ),
    );
  }
}

/// 状态/结果提示条。
class GlassBanner extends StatelessWidget {
  const GlassBanner({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.destructive : const Color(0xFF30A46C);
    return GlassPanel(
      radius: 14,
      sigma: 18,
      hoverable: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF3A3A3C),
                    letterSpacing: 0.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 胶囊选择器（超椭圆圆角）。
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shape = squircle(
      999,
      side: BorderSide(
        color: selected
            ? AppTheme.accent
            : Colors.white.withValues(alpha: dark ? 0.2 : 0.95),
        width: 0.9,
      ),
    );
    return GlassTappable(
      onTap: onTap,
      hoverScale: 1.05,
      child: AnimatedContainer(
        duration: Duration(milliseconds: reduceMotion(context) ? 0 : 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: ShapeDecoration(
          shape: shape,
          color: selected
              ? AppTheme.accent
              : Colors.white.withValues(alpha: dark ? 0.12 : 0.72),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected
                    ? Colors.white
                    : (dark ? Colors.white : const Color(0xFF1C1C1E)),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
        ),
      ),
    );
  }
}

/// 圆形勾选。
class GlassCheck extends StatelessWidget {
  const GlassCheck({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassTappable(
      onTap: () => onChanged(!value),
      hoverScale: 1.12,
      child: AnimatedContainer(
        duration: Duration(milliseconds: reduceMotion(context) ? 0 : 160),
        curve: Curves.easeOut,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? AppTheme.accent : Colors.transparent,
          border: Border.all(
            color: value
                ? AppTheme.accent
                : (dark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.22)),
            width: 1.6,
          ),
        ),
        child: value
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      ),
    );
  }
}

/// 玻璃输入框（超椭圆圆角 + 聚焦高亮）。
class GlassField extends StatefulWidget {
  const GlassField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<GlassField> {
  late final FocusNode _focus = FocusNode()
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final focused = _focus.hasFocus;

    final shape = squircle(
      14,
      side: BorderSide(
        color: focused
            ? AppTheme.accent
            : Colors.white.withValues(alpha: dark ? 0.16 : 0.95),
        width: focused ? 1.4 : 0.9,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(widget.label, style: theme.textTheme.labelSmall),
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: reduceMotion(context) ? 0 : 170),
          curve: Curves.easeOut,
          decoration: ShapeDecoration(
            shape: shape,
            color: Colors.white
                .withValues(alpha: dark ? 0.08 : (focused ? 0.98 : 0.80)),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: theme.textTheme.bodyMedium,
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodySmall,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

/// 二级页面外壳：玻璃导航条 + 背景。
class GlassPageScaffold extends StatelessWidget {
  const GlassPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuroraBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 18, 8),
              child: Row(
                children: [
                  GlassTappable(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(9),
                      radius: 999,
                      sigma: 16,
                      hoverable: false,
                      child: const Icon(Icons.chevron_left_rounded, size: 19),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 圆角图标徽标（超椭圆）。
class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.accent;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: squircle(11),
        color: tint.withValues(alpha: 0.13),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: tint),
      ),
    );
  }
}

/// 区块小标题。
Widget sectionHeader(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10, top: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

/// 次要说明文字。
Widget mutedText(
  BuildContext context,
  String text, {
  int maxLines = 2,
}) =>
    Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
