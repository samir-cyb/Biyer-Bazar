import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color background   = Color(0xFFFAFAED);
  static const Color surface      = Color(0xFFF5F3E8);
  static const Color crimson      = Color(0xFF800020);
  static const Color crimsonLight = Color(0xFFB00030);
  static const Color gold         = Color(0xFFD4AF37);
  static const Color goldLight    = Color(0xFFE8C84A);
  static const Color charcoal     = Color(0xFF1C1A17);
  static const Color charcoalMid  = Color(0xFF3D3A35);
  static const Color charcoalLight= Color(0xFF6B6660);

  // Glass & Overlay
  static const Color glassWhite     = Color(0x99FFFFFF);
  static const Color glassBorder    = Color(0x40FFFFFF);
  static const Color glassWhiteDark = Color(0x26FFFFFF);
  static const Color overlayDark    = Color(0x1A1C1A17);

  // Tier Colors
  static const Color premiumGold      = Color(0xFFD4AF37);
  static const Color premiumGoldBg    = Color(0x1AD4AF37);
  static const Color verifiedSilver   = Color(0xFF9E9E9E);
  static const Color verifiedSilverBg = Color(0x0F9E9E9E);
  static const Color freshTalent      = Color(0xFF2E7D32);
  static const Color freshTalentBg    = Color(0x142E7D32);
  static const Color freshTalentGlow  = Color(0x402E7D32);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error   = Color(0xFFB00020);
  static const Color divider = Color(0x1A1C1A17);

  // Budget Category Colors
  static const Color budgetVenue  = Color(0xFF800020);
  static const Color budgetAttire = Color(0xFFD4AF37);
  static const Color budgetDecor  = Color(0xFF6D4C41);
  static const Color budgetPhoto  = Color(0xFF37474F);
  static const Color budgetMakeup = Color(0xFF558B2F);
}

// ── Theme Extension for glass/glow/depth tokens ──────────────────────────────
class AppGlassTokens extends ThemeExtension<AppGlassTokens> {
  final Color glassBase;
  final Color glassBorder;
  final Color glowCrimson;
  final Color glowGold;
  final List<Color> meshColors;
  final Color cardShadowDeep;
  final Color cardShadowLight;

  const AppGlassTokens({
    required this.glassBase,
    required this.glassBorder,
    required this.glowCrimson,
    required this.glowGold,
    required this.meshColors,
    required this.cardShadowDeep,
    required this.cardShadowLight,
  });

  static const light = AppGlassTokens(
    glassBase:      Color(0xBBFFFFFF),
    glassBorder:    Color(0x55FFFFFF),
    glowCrimson:    Color(0x2A800020),
    glowGold:       Color(0x2AD4AF37),
    meshColors:     [Color(0xFFFFE4D0), Color(0xFFFFD6C2), Color(0xFFFFF4D0)],
    cardShadowDeep: Color(0x16000000),
    cardShadowLight:Color(0xAAFFFFFF),
  );

  @override
  AppGlassTokens copyWith({
    Color? glassBase, Color? glassBorder, Color? glowCrimson,
    Color? glowGold, List<Color>? meshColors,
    Color? cardShadowDeep, Color? cardShadowLight,
  }) => AppGlassTokens(
    glassBase:      glassBase ?? this.glassBase,
    glassBorder:    glassBorder ?? this.glassBorder,
    glowCrimson:    glowCrimson ?? this.glowCrimson,
    glowGold:       glowGold ?? this.glowGold,
    meshColors:     meshColors ?? this.meshColors,
    cardShadowDeep: cardShadowDeep ?? this.cardShadowDeep,
    cardShadowLight:cardShadowLight ?? this.cardShadowLight,
  );

  @override
  AppGlassTokens lerp(AppGlassTokens? other, double t) {
    if (other == null) return this;
    return AppGlassTokens(
      glassBase:      Color.lerp(glassBase, other.glassBase, t)!,
      glassBorder:    Color.lerp(glassBorder, other.glassBorder, t)!,
      glowCrimson:    Color.lerp(glowCrimson, other.glowCrimson, t)!,
      glowGold:       Color.lerp(glowGold, other.glowGold, t)!,
      meshColors:     meshColors,
      cardShadowDeep: Color.lerp(cardShadowDeep, other.cardShadowDeep, t)!,
      cardShadowLight:Color.lerp(cardShadowLight, other.cardShadowLight, t)!,
    );
  }
}
