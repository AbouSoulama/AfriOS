import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/afri_colors.dart';
import 'afri_premium.dart';

/// Living mesh background. Blobs are radial gradients that fade to transparent,
/// so we get soft light without paying for a real blur pass.
class AfriMeshBackground extends StatefulWidget {
  const AfriMeshBackground({
    super.key,
    required this.child,
    this.animate = true,
    this.overlayStyle = SystemUiOverlayStyle.dark,
  });

  final Widget child;
  final bool animate;

  /// Status bar icon contrast. Screens whose top edge is a dark hero pass
  /// [SystemUiOverlayStyle.light] instead.
  final SystemUiOverlayStyle overlayStyle;

  @override
  State<AfriMeshBackground> createState() => _AfriMeshBackgroundState();
}

class _AfriMeshBackgroundState extends State<AfriMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: widget.overlayStyle.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FBFA), AfriColors.mist],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * 2 * math.pi;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _blob(
                    top: -120,
                    right: -100 + math.sin(t) * 18,
                    size: 320,
                    color: AfriColors.teal.withValues(alpha: 0.16),
                  ),
                  _blob(
                    top: 200 + math.cos(t) * 22,
                    left: -140,
                    size: 340,
                    color: AfriColors.gold.withValues(alpha: 0.14),
                  ),
                  _blob(
                    bottom: -60,
                    right: -80 + math.cos(t * 0.8) * 24,
                    size: 280,
                    color: AfriColors.tealBright.withValues(alpha: 0.12),
                  ),
                ],
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _blob({
    required double size,
    required Color color,
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0.05, 1],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed photo plane with a cinematic veil. When [kenBurns] is on the image
/// slowly drifts and scales, which is what makes the onboarding slides feel
/// like film rather than static screenshots.
class AfriHeroImage extends StatefulWidget {
  const AfriHeroImage({
    super.key,
    required this.asset,
    this.child,
    this.alignment = Alignment.center,
    this.kenBurns = false,
    this.veil = AfriColors.aurora,
    this.reverse = false,
  });

  final String asset;
  final Widget? child;
  final Alignment alignment;
  final bool kenBurns;
  final Gradient veil;
  final bool reverse;

  @override
  State<AfriHeroImage> createState() => _AfriHeroImageState();
}

class _AfriHeroImageState extends State<AfriHeroImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    if (widget.kenBurns) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      widget.asset,
      fit: BoxFit.cover,
      alignment: widget.alignment,
      errorBuilder: (_, __, ___) => const DecoratedBox(
        decoration: BoxDecoration(gradient: AfriColors.heroGradient),
      ),
    );

    if (widget.kenBurns) {
      image = AnimatedBuilder(
        animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        builder: (context, child) {
          final v = Curves.easeInOut.transform(_c.value);
          final dir = widget.reverse ? -1.0 : 1.0;
          return Transform.scale(
            scale: 1.06 + v * 0.10,
            alignment: Alignment(dir * (-0.3 + v * 0.6), -0.2 + v * 0.4),
            child: child,
          );
        },
        child: image,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        DecoratedBox(decoration: BoxDecoration(gradient: widget.veil)),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class AfriSectionHeader extends StatelessWidget {
  const AfriSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.accent = true,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (accent) ...[
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: AfriColors.tealGlow,
              borderRadius: BorderRadius.circular(AfriRadius.pill),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AfriQuickAction extends StatelessWidget {
  const AfriQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AfriColors.teal,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AfriPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AfriSpace.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AfriRadius.rLg,
          border: Border.all(color: AfriColors.line),
          boxShadow: AfriShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: AfriRadius.rSm,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AfriSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AfriColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AfriColors.slateLight),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AfriColors.slateLight,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }
}

class AfriFadeSlide extends StatelessWidget {
  const AfriFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginY = 0.06,
  });

  final Widget child;
  final Duration delay;
  final double beginY;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(
            begin: beginY,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic);
  }
}

/// Staggers a column of children so lists cascade in instead of popping.
class AfriStagger extends StatelessWidget {
  const AfriStagger({
    super.key,
    required this.children,
    this.interval = const Duration(milliseconds: 70),
    this.beginY = 0.08,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final Duration interval;
  final double beginY;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          AfriFadeSlide(
            delay: interval * i,
            beginY: beginY,
            child: children[i],
          ),
      ],
    );
  }
}
