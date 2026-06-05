import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard — frosted glass surface with layered shadows for depth.
// RepaintBoundary wraps BackdropFilter to isolate compositor cost.
// On low-end devices: set blurSigma = 0 to skip blur entirely while keeping
// the glass look via the layered shadow + border combo.
// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.blurSigma = 0,   // Default 0 = no BackdropFilter → max performance
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.boxShadow,
    this.onTap,
    this.width,
    this.height,
  });

  List<BoxShadow> get _defaultShadows => [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.80),
      blurRadius: 1,
      offset: const Offset(0, -1),
      spreadRadius: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.glassWhite;
    final border = borderColor ?? AppColors.glassBorder;

    Widget inner = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1.2),
        // Top-left highlight to simulate light hitting glass from upper-left
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.35),
            bg.withOpacity(0.0),
          ],
          stops: const [0.0, 0.55],
        ),
        boxShadow: boxShadow ?? _defaultShadows,
      ),
      child: child,
    );

    // Only add BackdropFilter if caller explicitly requests blur > 0
    if (blurSigma > 0) {
      inner = RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: inner,
          ),
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: inner,
      );
    }

    Widget card = Container(margin: margin, child: inner);

    if (onTap != null) {
      return PressableCard(onTap: onTap!, child: card);
    }
    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PressableCard — scale-down-on-press micro-interaction. Very cheap (just
// a transform, no compositing layers). Works on the oldest phones.
// ─────────────────────────────────────────────────────────────────────────────
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.970,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TiltCard — 3D parallax tilt effect via Matrix4. Zero GPU compositor cost —
// it's just a perspective transform. Runs smoothly on any device.
// ─────────────────────────────────────────────────────────────────────────────
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTiltDegrees;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTiltDegrees = 8.0,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard>
    with SingleTickerProviderStateMixin {
  double _rotX = 0.0;
  double _rotY = 0.0;

  late final AnimationController _resetCtrl;
  late Animation<double> _rxAnim;
  late Animation<double> _ryAnim;

  @override
  void initState() {
    super.initState();
    _resetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _resetCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d, BoxConstraints c) {
    _resetCtrl.stop();
    final nx = d.localPosition.dx / c.maxWidth - 0.5;
    final ny = d.localPosition.dy / c.maxHeight - 0.5;
    final rad = widget.maxTiltDegrees * (math_pi / 180);
    setState(() {
      _rotY = nx * rad;
      _rotX = -ny * rad;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    _rxAnim = Tween<double>(begin: _rotX, end: 0.0).animate(
      CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _rotX = _rxAnim.value));
    _ryAnim = Tween<double>(begin: _rotY, end: 0.0).animate(
      CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _rotY = _ryAnim.value));
    _resetCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onPanUpdate: (d) => _onPanUpdate(d, constraints),
        onPanEnd: _onPanEnd,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(_rotX)
            ..rotateY(_rotY),
          child: widget.child,
        ),
      );
    });
  }
}

// dart:math pi — inline to avoid extra import in this file
const double math_pi = 3.1415926535897932;

// ─────────────────────────────────────────────────────────────────────────────
// GoldGlassCard & FreshTalentGlassCard — tier-specific variants
// ─────────────────────────────────────────────────────────────────────────────
class GoldGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GoldGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      backgroundColor: AppColors.premiumGoldBg,
      borderColor: AppColors.gold.withOpacity(0.45),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withOpacity(0.20),
          blurRadius: 28,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.90),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
      child: child,
    );
  }
}

class FreshTalentGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const FreshTalentGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  State<FreshTalentGlassCard> createState() => _FreshTalentGlassCardState();
}

class _FreshTalentGlassCardState extends State<FreshTalentGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.25, end: 0.70)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => GlassCard(
        padding: widget.padding,
        margin: widget.margin,
        onTap: widget.onTap,
        backgroundColor: AppColors.freshTalentBg,
        borderColor: AppColors.freshTalent.withOpacity(_glow.value * 0.7),
        boxShadow: [
          BoxShadow(
            color: AppColors.freshTalent.withOpacity(_glow.value * 0.22),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GlowContainer — drop-in replacement for a container that needs a glow ring.
// Uses BoxShadow (cheap) not BackdropFilter.
// ─────────────────────────────────────────────────────────────────────────────
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final double borderRadius;
  final Color? backgroundColor;

  const GlowContainer({
    super.key,
    required this.child,
    required this.glowColor,
    this.glowRadius = 20,
    this.borderRadius = 16,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.35),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.15),
            blurRadius: glowRadius * 2,
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}
