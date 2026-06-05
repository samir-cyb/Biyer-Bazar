import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FloatingNavBar — Light glass pill with sliding crimson bubble indicator.
// Active item: icon + label. Inactive: icon only (no label clutter).
// Press-spring micro-interaction + haptic feedback on every tap.
// ─────────────────────────────────────────────────────────────────────────────
class FloatingNavBar extends StatelessWidget {
  final List<(IconData, String)> items;
  final int selected;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 14),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: const Color(0xFFEDE7D5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.13),
                    blurRadius: 36,
                    offset: const Offset(0, 12),
                    spreadRadius: -6,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  // Top inner highlight — gives the bar a lifted, premium feel
                  BoxShadow(
                    color: Colors.white.withOpacity(0.95),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // ── Sliding crimson bubble ────────────────────────────────
                  _SlidingBubble(count: items.length, selected: selected),
                  // ── Tab items ─────────────────────────────────────────────
                  Row(
                    children: items.asMap().entries.map((e) {
                      final i = e.key;
                      return Expanded(
                        child: _NavItem(
                          icon: e.value.$1,
                          label: e.value.$2,
                          isSelected: i == selected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onTap(i);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliding crimson gradient bubble — glides behind the active icon.
// Inner shimmer overlay gives it a glassy, premium surface quality.
// ─────────────────────────────────────────────────────────────────────────────
class _SlidingBubble extends StatelessWidget {
  final int count;
  final int selected;

  const _SlidingBubble({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final itemW = constraints.maxWidth / count;
      // AnimatedPositioned must be a direct child of Stack
      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: itemW * selected + 10,
            top: 7,
            bottom: 7,
            width: itemW - 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF950025), AppColors.crimson],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.48),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppColors.crimson.withOpacity(0.20),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              // Inner highlight — top gloss strip
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual tab item.
// - Press: scales down to 0.88 on tap-down, springs back on release.
// - Icon: TweenAnimationBuilder scale-pop with easeOutBack spring curve.
// - Label: only visible when selected — AnimatedSize reveal + flutter_animate.
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 250),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _pressCtrl.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon with spring scale pop ──────────────────────────────────
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              tween: Tween(end: widget.isSelected ? 1.16 : 1.0),
              builder: (_, scale, __) => Transform.scale(
                scale: scale,
                child: Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? Colors.white
                      : AppColors.charcoalLight,
                  size: 21,
                ),
              ),
            ),

            // ── Label — appears only for selected, fades + slides in ────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: widget.isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        widget.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          .animate(key: ValueKey('label_${widget.label}'))
                          .fadeIn(duration: 180.ms)
                          .slideY(
                            begin: 0.5,
                            end: 0,
                            duration: 220.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
