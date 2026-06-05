import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedProgressBar — glowing gradient bar with shimmer sweep.
// Uses AnimatedContainer (very cheap) + BoxShadow glow.
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? endColor; // optional gradient end color

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.borderRadius = 100,
    this.backgroundColor,
    this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final grad2 = endColor ?? color.withOpacity(0.6);

    return LayoutBuilder(
      builder: (_, constraints) => Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Stack(
          children: [
            // Fill bar
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                width: constraints.maxWidth * clamped,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    colors: [color, grad2],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: height * 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            // Leading glow dot
            if (clamped > 0.02)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                left: (constraints.maxWidth * clamped - height).clamp(0, double.infinity),
                top: 0,
                bottom: 0,
                child: Container(
                  width: height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.85),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: height * 3,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
