import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

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
    this.blurSigma = 12,
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

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: 1.2,
            ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(margin: margin, child: card),
      );
    }
    return Container(margin: margin, child: card);
  }
}

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
          color: AppColors.gold.withOpacity(0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
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
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GlassCard(
          padding: widget.padding,
          margin: widget.margin,
          onTap: widget.onTap,
          backgroundColor: AppColors.freshTalentBg,
          borderColor:
              AppColors.freshTalent.withOpacity(_glowAnimation.value * 0.7),
          boxShadow: [
            BoxShadow(
              color: AppColors.freshTalent
                  .withOpacity(_glowAnimation.value * 0.25),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          child: widget.child,
        );
      },
    );
  }
}
