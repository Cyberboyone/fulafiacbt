import 'dart:math';
import 'package:flutter/material.dart';

enum ConfettiShape { circle, square, triangle, arc }

class ConfettiPiece {
  final ConfettiShape shape;
  final Color color;
  final double size;
  final double startX;
  final double speed;
  final double wobbleAmp;
  final double wobbleFreq;
  final double rotationSpeed;
  final double delay;

  ConfettiPiece({
    required this.shape,
    required this.color,
    required this.size,
    required this.startX,
    required this.speed,
    required this.wobbleAmp,
    required this.wobbleFreq,
    required this.rotationSpeed,
    required this.delay,
  });
}

class ConfettiAnimation extends StatefulWidget {
  final bool show;
  final int pieceCount;

  const ConfettiAnimation({
    super.key,
    required this.show,
    this.pieceCount = 50,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiPiece> _pieces;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _generatePieces();
    if (widget.show) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _generatePieces();
      _controller.repeat();
    } else if (!widget.show && oldWidget.show) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generatePieces() {
    final colors = [
      const Color(0xFFE53935), // red
      const Color(0xFFFF9800), // orange
      const Color(0xFFFFC107), // yellow
      const Color(0xFF4CAF50), // green
      const Color(0xFF00BCD4), // teal
      const Color(0xFF2196F3), // blue
      const Color(0xFF9C27B0), // purple
      const Color(0xFFFF5722), // deep orange
    ];

    final shapes = ConfettiShape.values;

    _pieces = List.generate(widget.pieceCount, (_) {
      return ConfettiPiece(
        shape: shapes[_rng.nextInt(shapes.length)],
        color: colors[_rng.nextInt(colors.length)],
        size: 6 + _rng.nextDouble() * 12,
        startX: _rng.nextDouble(),
        speed: 0.6 + _rng.nextDouble() * 0.8,
        wobbleAmp: 15 + _rng.nextDouble() * 30,
        wobbleFreq: 2 + _rng.nextDouble() * 3,
        rotationSpeed: 2 + _rng.nextDouble() * 4,
        delay: _rng.nextDouble() * 0.3,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(
            pieces: _pieces,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final adjustedProgress = (progress - piece.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final t = adjustedProgress;

      // Y position: fall from top to beyond bottom
      final y = -30.0 + (size.height + 80) * t * piece.speed;

      // X wobble
      final baseX = piece.startX * size.width;
      final x = baseX + sin(t * piece.wobbleFreq * pi * 2) * piece.wobbleAmp;

      // Rotation
      final rotation = t * piece.rotationSpeed * pi * 2;

      // Opacity: fade in, full, fade out
      double opacity;
      if (t < 0.1) {
        opacity = t / 0.1;
      } else if (t > 0.85) {
        opacity = (1.0 - t) / 0.15;
      } else {
        opacity = 1.0;
      }
      opacity = opacity.clamp(0.0, 1.0);

      final paint = Paint()
        ..color = piece.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final s = piece.size;

      switch (piece.shape) {
        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, s / 2, paint);
          break;

        case ConfettiShape.square:
          final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
          canvas.drawRect(rect, paint);
          break;

        case ConfettiShape.triangle:
          final path = Path()
            ..moveTo(0, -s / 2)
            ..lineTo(s / 2, s / 2)
            ..lineTo(-s / 2, s / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case ConfettiShape.arc:
          final arcPaint = Paint()
            ..color = piece.color.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round;
          final arcRect = Rect.fromCenter(center: Offset.zero, width: s * 1.5, height: s);
          canvas.drawArc(arcRect, 0, pi * 1.3, false, arcPaint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
