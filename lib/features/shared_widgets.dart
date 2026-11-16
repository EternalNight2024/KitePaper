import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_theme.dart';

/// 玻璃操作按钮（文字 + 图标），统一全站交互材质。
class ActionGlassButton extends StatelessWidget {
  const ActionGlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.prominent = false,
    this.compact = false,
    this.destructive = false,
    this.accent,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// 主操作：使用实心石墨胶囊，保证灰白色系下的文字对比度。
  final bool prominent;
  final bool compact;
  final bool destructive;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // 主操作在浅色模式用深石墨 + 白字，暗色模式用浅色 + 深字，
    // 始终与所在表面形成对比。
    final color = destructive
        ? theme.colorScheme.error
        : (prominent
            ? (dark ? const Color(0xFF1C1C1E) : Colors.white)
            : (dark ? Colors.white : const Color(0xFF1C1C1E)));

    // 明确给内容一个撑满按钮的高度：GlassButton.custom 的 height 只会约束
    // 外层 SizedBox，内部 Align 会把子项约束放松，若不撑高，实心胶囊会
    // 塌缩成文字高度，看起来比玻璃按钮矮一截。
    final h = compact ? 42.0 : 48.0;
    final content = SizedBox(
      height: h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 15 : 19),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 16 : 18, color: color),
            SizedBox(width: compact ? 6 : 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: compact ? 13.5 : 14.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    // 主操作用实心石墨胶囊（iOS tinted prominent 观感），
    // 次级操作保留玻璃表面，保证灰白底上的可读性。
    final button = prominent
        ? GlassButton.custom(
            onTap: onTap ?? () {},
            enabled: onTap != null,
            height: h,
            style: GlassButtonStyle.transparent,
            shape: const LiquidRoundedSuperellipse(borderRadius: 14),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const LiquidRoundedSuperellipse(borderRadius: 14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [accent ?? AppTheme.accent, AppTheme.accentDeep]
                      : accent == null
                          ? const [Color(0xFF56565C), Color(0xFF3B3B40)]
                          : [accent!, Color.lerp(accent!, Colors.black, 0.2)!],
                ),
              ),
              child: content,
            ),
          )
        : GlassButton.custom(
            onTap: onTap ?? () {},
            enabled: onTap != null,
            height: h,
            style: GlassButtonStyle.filled,
            shape: const LiquidRoundedSuperellipse(borderRadius: 14),
            child: content,
          );

    return button;
  }
}

/// 页首信息卡：图标 + 标题 + 说明。
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tint ?? AppTheme.accent;
    return GlassContainer.card(
      surfaceStyle: GlassSurfaceStyle.solid,
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 圆形勾选标记（纯色，避免在实色卡片内嵌套玻璃）。
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: 23,
        height: 23,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppTheme.accent : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppTheme.accent
                : CupertinoColors.systemGrey3.resolveFrom(context),
            width: 1.5,
          ),
        ),
        child: selected
            ? const Icon(CupertinoIcons.checkmark, size: 13, color: Colors.white)
            : null,
      );
}
