import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'layout.dart';

/// 把桌面鼠标位置映射到光源角度，交给库原生的 [GlassMotionScope]。
///
/// 与自绘缩放不同，[GlassMotionScope] 直接改写玻璃主题里的 `lightAngle`，
/// 由库的 shader 重新计算镜面高光方向 —— 高光会随鼠标在玻璃面板、按钮、
/// 标签栏上流动，这是真正的「液态玻璃原生动画」，且全站统一生效。
///
/// 只在宽屏（桌面）启用；窄屏触屏与系统「减弱动态效果」时原样透传。
class NativeGlassMotion extends StatefulWidget {
  const NativeGlassMotion({super.key, required this.child});

  final Widget child;

  @override
  State<NativeGlassMotion> createState() => _NativeGlassMotionState();
}

class _NativeGlassMotionState extends State<NativeGlassMotion> {
  final StreamController<double> _lightAngle =
      StreamController<double>.broadcast();

  double _lastAngle = -1;
  bool _lastWide = false;

  @override
  void dispose() {
    _lightAngle.close();
    super.dispose();
  }

  void _onHover(PointerHoverEvent event) {
    final wide = isWideScreen(context);
    if (_lastWide != wide) {
      // 跨越布局断点时清掉旧角度，避免窄屏残留。
      _lastWide = wide;
      if (!wide) {
        _lastAngle = -1;
        _lightAngle.add(0.75 * pi);
      }
    }
    if (!wide) return;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;

    final width = MediaQuery.sizeOf(context).width;
    // 鼠标从左到右移动：光源角度在 0.25π ~ 1.25π 之间平滑扫过。
    final t = (event.localPosition.dx / width).clamp(0.0, 1.0);
    final angle = (0.25 + t) * pi;
    // 量化到约 4° 一档，避免鼠标每像素移动都重建整棵玻璃子树。
    const step = pi / 45;
    final quantized = (angle / step).round() * step;
    if ((quantized - _lastAngle).abs() < step / 2) return;
    _lastAngle = quantized;
    if (!_lightAngle.isClosed) _lightAngle.add(quantized);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerHover: _onHover,
        behavior: HitTestBehavior.translucent,
        child: GlassMotionScope(
          lightAngle: isWideScreen(context) ? _lightAngle.stream : null,
          child: widget.child,
        ),
      );
}
