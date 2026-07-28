import 'package:flutter/material.dart';

/// AfriOS visual language — "Dakar Dawn"
/// Deep ink + living teal + gold pulse. Mist surfaces, never flat grey.
class AfriColors {
  // Brand core
  static const teal = Color(0xFF0E9F8F);
  static const tealBright = Color(0xFF17C2AC);
  static const tealDark = Color(0xFF0A7A6E);
  static const tealDeep = Color(0xFF064F49);
  static const tealSoft = Color(0xFFD8F5F0);
  static const tealMist = Color(0xFFEDFBF8);

  // Gold / amber accent
  static const amber = Color(0xFFE8A838);
  static const gold = Color(0xFFD9A441);
  static const goldBright = Color(0xFFF5C463);
  static const amberSoft = Color(0xFFFFF3D6);

  // Support
  static const green = Color(0xFF1FA97A);
  static const orange = Color(0xFFF07A3A);
  static const violet = Color(0xFF6C5CE7);

  // Neutrals
  static const navy = Color(0xFF13233F);
  static const ink = Color(0xFF080D18);
  static const inkSoft = Color(0xFF111A2B);
  static const slate = Color(0xFF5B6B7C);
  static const slateLight = Color(0xFF8C9AA8);
  static const mist = Color(0xFFF4F7F6);
  static const mistDeep = Color(0xFFE6EDEA);
  static const line = Color(0xFFEDF2F0);

  // Legacy aliases
  static const sand = Color(0xFFF4F7F6);
  static const warm = Color(0xFFFFF3D6);
  static const wave = Color(0xFF00B389);
  static const orangeMoney = Color(0xFFFF7900);

  // Semantic
  static const error = Color(0xFFE24747);
  static const success = Color(0xFF1FA97A);
  static const warning = Color(0xFFE8A838);

  // ── Gradients ────────────────────────────────────────────────
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080D18), Color(0xFF13233F), Color(0xFF064F49)],
  );

  static const tealGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17C2AC), Color(0xFF0A7A6E)],
  );

  static const goldGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5C463), Color(0xFFD9A441)],
  );

  /// Vertical veil that keeps photo slides legible under text.
  static const aurora = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.42, 0.72, 1.0],
    colors: [
      Color(0x33080D18),
      Color(0x66080D18),
      Color(0xE6080D18),
      Color(0xFF080D18),
    ],
  );

  /// Subtle top-down sheen for glass surfaces.
  static LinearGradient get glassSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.06),
        ],
      );

  static LinearGradient get darkGlassSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.04),
        ],
      );

  /// Shimmer sweep used by skeleton loaders.
  static LinearGradient get shimmer => LinearGradient(
        begin: const Alignment(-1.2, -0.3),
        end: const Alignment(1.2, 0.3),
        colors: [
          mistDeep.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.92),
          mistDeep.withValues(alpha: 0.55),
        ],
        stops: const [0.15, 0.5, 0.85],
      );
}

/// Corner radius scale.
class AfriRadius {
  static const xs = 10.0;
  static const sm = 14.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const xxl = 34.0;
  static const pill = 999.0;

  static BorderRadius get rXs => BorderRadius.circular(xs);
  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rXxl => BorderRadius.circular(xxl);
}

/// Spacing scale — keeps rhythm consistent across screens.
class AfriSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xxl = 36.0;
}

/// Elevation tokens — layered soft shadows instead of hard Material drops.
class AfriShadow {
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AfriColors.ink.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AfriColors.ink.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AfriColors.ink.withValues(alpha: 0.03),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: AfriColors.ink.withValues(alpha: 0.10),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: AfriColors.ink.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.32}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Shared animation timings so motion feels like one system.
class AfriMotionSpec {
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const page = Duration(milliseconds: 380);

  static const emphasized = Curves.easeOutCubic;
  static const smooth = Curves.easeOutQuart;
  static const spring = Curves.easeOutBack;
}
