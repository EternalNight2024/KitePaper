import 'package:flutter/material.dart';

/// 应用壁纸背景。
///
/// 液态玻璃的「颜色吸收」依赖背后的纹理层次（[GlassScaffold] 在传入
/// `background` 时会自动开启 `enableBackgroundSampling`）。因此这里不是
/// 纯色平涂，而是有明确明暗层次的灰白渐变 + 柔光光斑：
/// 浅色模式下让白色实色卡片能浮出背景，深色模式下保持通透的层次。
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF07070A), Color(0xFF15151A), Color(0xFF0A0A0D)]
                : const [Color(0xFFE7E8ED), Color(0xFFF7F8FA), Color(0xFFE2E3E9)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _pool(
              dark ? const Color(0x14FFFFFF) : const Color(0x9AB3C7F0),
              const Alignment(-0.85, -0.95),
              1.35,
            ),
            _pool(
              dark ? const Color(0x10E8F0FF) : const Color(0x668FE0D6),
              const Alignment(0.95, -0.45),
              1.05,
            ),
            _pool(
              dark ? const Color(0x0CE0D8F0) : const Color(0x4DD9C4D8),
              const Alignment(-0.2, 1.1),
              1.25,
            ),
          ],
        ),
      ),
    );
  }

  /// 大半径柔光光斑，为玻璃提供可被折射的明暗层次。
  Widget _pool(Color color, Alignment alignment, double scale) => Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: scale,
          heightFactor: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0)],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      );
}

/// 壁纸底色，用于滚动边缘渐隐（GlassScaffold.backgroundColor）。
Color appBackgroundColor(Brightness brightness) =>
    brightness == Brightness.dark ? const Color(0xFF0B0B0E) : const Color(0xFFEDEFF3);
