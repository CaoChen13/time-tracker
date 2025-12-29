import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Magic UI 风格的边框光束效果
/// 一个渐变色块沿着边框路径循环移动
class BorderBeam extends StatefulWidget {
  final double size;
  final Duration duration;
  final Duration delay;
  final Color colorFrom;
  final Color colorTo;
  final double borderWidth;
  final double borderRadius;
  final bool reverse;

  const BorderBeam({
    super.key,
    this.size = 100,
    this.duration = const Duration(seconds: 6),
    this.delay = Duration.zero,
    this.colorFrom = const Color(0xFFFFAA40),
    this.colorTo = const Color(0xFF9C40FF),
    this.borderWidth = 2,
    this.borderRadius = 24,
    this.reverse = false,
  });

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BorderBeamPainter(
            progress:
                widget.reverse ? 1 - _controller.value : _controller.value,
            size: widget.size,
            colorFrom: widget.colorFrom,
            colorTo: widget.colorTo,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _BorderBeamPainter extends CustomPainter {
  final double progress;
  final double size;
  final Color colorFrom;
  final Color colorTo;
  final double borderWidth;
  final double borderRadius;

  _BorderBeamPainter({
    required this.progress,
    required this.size,
    required this.colorFrom,
    required this.colorTo,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // 创建圆角矩形路径
    final rect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    // 使用 PathMetrics 获取路径上的点（确保速度均匀）
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;

    // 当前位置
    final currentDistance = progress * totalLength;

    // 获取路径上的切线信息
    final tangent = pathMetrics.getTangentForOffset(currentDistance);
    if (tangent == null) return;

    final point = tangent.position;
    final angle = tangent.angle;

    // 保存画布状态
    canvas.save();

    // 裁剪到边框区域
    final outerRRect = rrect.inflate(borderWidth / 2);
    final innerRRect = rrect.deflate(borderWidth / 2);
    final clipPath = Path()
      ..addRRect(outerRRect)
      ..addRRect(innerRRect)
      ..fillType = PathFillType.evenOdd;
    canvas.clipPath(clipPath);

    // 移动到光束位置并旋转
    canvas.translate(point.dx, point.dy);
    canvas.rotate(angle);

    // 绘制渐变光束
    final beamRect = Rect.fromCenter(
      center: Offset.zero,
      width: size,
      height: borderWidth * 6,
    );

    final gradient = ui.Gradient.linear(
      Offset(-size / 2, 0),
      Offset(size / 2, 0),
      [
        colorFrom.withOpacity(0),
        colorFrom,
        colorTo,
        colorTo.withOpacity(0),
      ],
      [0.0, 0.3, 0.7, 1.0],
    );

    final beamPaint = Paint()..shader = gradient;
    canvas.drawRect(beamRect, beamPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BorderBeamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
