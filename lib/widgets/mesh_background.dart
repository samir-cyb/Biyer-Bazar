import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedMeshBackground
// Uses a single CustomPainter — zero BackdropFilter, runs on any phone.
// RepaintBoundary is applied internally so only this widget repaints.
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedMeshBackground extends StatefulWidget {
  final Widget child;
  final bool dark; // true → dark wedding night, false → light airy cream

  const AnimatedMeshBackground({
    super.key,
    required this.child,
    this.dark = false,
  });

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _MeshPainter(t: _ctrl.value, dark: widget.dark),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  final bool dark;
  const _MeshPainter({required this.t, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Base fill
    canvas.drawRect(
      Offset.zero & size,
      paint
        ..color = dark ? const Color(0xFF180810) : const Color(0xFFFAFAED)
        ..shader = null,
    );

    final tau = math.pi * 2;

    // Blob 1 — top-left warm glow (crimson/rose)
    final b1 = Offset(
      size.width * (0.08 + 0.12 * math.sin(t * tau)),
      size.height * (0.10 + 0.08 * math.cos(t * tau * 0.7)),
    );
    final r1 = size.width * 0.52;
    canvas.drawCircle(
      b1,
      r1,
      paint
        ..shader = RadialGradient(colors: [
          dark
              ? const Color(0xFF800020).withOpacity(0.30)
              : const Color(0xFF800020).withOpacity(0.12),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: b1, radius: r1)),
    );

    // Blob 2 — bottom-right gold glow
    final b2 = Offset(
      size.width * (0.82 - 0.10 * math.sin(t * tau * 0.9 + 1.0)),
      size.height * (0.78 + 0.07 * math.cos(t * tau * 0.8 + 2.0)),
    );
    final r2 = size.width * 0.50;
    canvas.drawCircle(
      b2,
      r2,
      paint
        ..shader = RadialGradient(colors: [
          dark
              ? const Color(0xFFD4AF37).withOpacity(0.22)
              : const Color(0xFFD4AF37).withOpacity(0.10),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: b2, radius: r2)),
    );

    // Blob 3 — center accent (softer rose)
    final b3 = Offset(
      size.width * (0.48 + 0.06 * math.cos(t * tau * 1.1 + 0.5)),
      size.height * (0.42 - 0.05 * math.sin(t * tau * 1.3 + 1.0)),
    );
    final r3 = size.width * 0.38;
    canvas.drawCircle(
      b3,
      r3,
      paint
        ..shader = RadialGradient(colors: [
          dark
              ? const Color(0xFF4A0020).withOpacity(0.20)
              : const Color(0xFFFFCDD2).withOpacity(0.30),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: b3, radius: r3)),
    );
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t || old.dark != dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// StaticMeshBackground — no animation. Zero CPU cost. For non-auth screens.
// ─────────────────────────────────────────────────────────────────────────────
class StaticMeshBackground extends StatelessWidget {
  final Widget child;
  const StaticMeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _StaticMeshPainter(),
      child: child,
    );
  }
}

class _StaticMeshPainter extends CustomPainter {
  const _StaticMeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    canvas.drawRect(
      Offset.zero & size,
      paint..color = AppColors.background..shader = null,
    );

    final b1 = Offset(size.width * 0.1, size.height * 0.12);
    final r1 = size.width * 0.45;
    canvas.drawCircle(b1, r1,
      paint..shader = RadialGradient(colors: [
        AppColors.crimson.withOpacity(0.07), Colors.transparent,
      ]).createShader(Rect.fromCircle(center: b1, radius: r1)));

    final b2 = Offset(size.width * 0.85, size.height * 0.80);
    final r2 = size.width * 0.42;
    canvas.drawCircle(b2, r2,
      paint..shader = RadialGradient(colors: [
        AppColors.gold.withOpacity(0.07), Colors.transparent,
      ]).createShader(Rect.fromCircle(center: b2, radius: r2)));
  }

  @override
  bool shouldRepaint(_StaticMeshPainter old) => false;
}
