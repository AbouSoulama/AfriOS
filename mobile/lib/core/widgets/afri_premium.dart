import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../theme/afri_colors.dart';

/// Frosted glass surface. Blur is intentionally cheap (sigma <= 18) so mid-range
/// Android devices keep 60fps.
class AfriGlass extends StatelessWidget {
  const AfriGlass({
    super.key,
    required this.child,
    this.blur = 14,
    this.radius = AfriRadius.lg,
    this.dark = false,
    this.padding,
    this.tint,
    this.border = true,
    this.shadows,
  });

  final Widget child;
  final double blur;
  final double radius;
  final bool dark;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final bool border;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final fill = tint ??
        (dark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.72));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: borderRadius,
              border: border
                  ? Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.65),
                      width: 1,
                    )
                  : null,
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap target that dips slightly and fires a light haptic — the single
/// interaction primitive used for every custom card in the app.
class AfriPressable extends StatefulWidget {
  const AfriPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final BorderRadius? borderRadius;

  @override
  State<AfriPressable> createState() => _AfriPressableState();
}

class _AfriPressableState extends State<AfriPressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!.call();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!.call();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AfriMotionSpec.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Sweeping skeleton placeholder used while data loads.
class AfriShimmer extends StatefulWidget {
  const AfriShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AfriRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AfriShimmer> createState() => _AfriShimmerState();
}

class _AfriShimmerState extends State<AfriShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * 2 - 1;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(t - 0.6, 0),
                  end: Alignment(t + 0.6, 0),
                  colors: [
                    AfriColors.mistDeep,
                    Colors.white.withValues(alpha: 0.85),
                    AfriColors.mistDeep,
                  ],
                  stops: const [0.1, 0.5, 0.9],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Card-shaped skeleton group, matching the real list tile rhythm.
class AfriSkeletonTile extends StatelessWidget {
  const AfriSkeletonTile({super.key, this.showAvatar = true});

  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AfriSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AfriRadius.rLg,
        border: Border.all(color: AfriColors.line),
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            const AfriShimmer(width: 46, height: 46, radius: AfriRadius.sm),
            const SizedBox(width: AfriSpace.sm),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AfriShimmer(width: 150, height: 14),
                SizedBox(height: AfriSpace.xs),
                AfriShimmer(width: 90, height: 11),
              ],
            ),
          ),
          const AfriShimmer(width: 62, height: 22, radius: AfriRadius.pill),
        ],
      ),
    );
  }
}

class AfriSkeletonList extends StatelessWidget {
  const AfriSkeletonList({super.key, this.count = 5, this.showAvatar = true});

  final int count;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AfriSpace.md, AfriSpace.xs, AfriSpace.md, 120),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AfriSpace.sm),
      itemBuilder: (_, __) => AfriSkeletonTile(showAvatar: showAvatar),
    );
  }
}

/// Money value that rolls up from zero — makes dashboards feel alive.
class AfriAnimatedAmount extends StatelessWidget {
  const AfriAnimatedAmount({
    super.key,
    required this.amount,
    this.currency = 'FCFA',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final num amount;
  final String currency;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,###', 'fr_FR');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        '${format.format(value.round())} $currency',
        style: style,
      ),
    );
  }
}

/// Text painted with a brand gradient.
class AfriGradientText extends StatelessWidget {
  const AfriGradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AfriColors.tealGlow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}

/// Circular progress ring with a centred label — used for stock and goals.
class AfriProgressRing extends StatelessWidget {
  const AfriProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 7,
    this.color = AfriColors.teal,
    this.label,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          if (label != null) label!,
        ],
      ),
    );
  }
}

/// Segmented pill selector with a sliding indicator.
class AfriPillTabs extends StatelessWidget {
  const AfriPillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AfriRadius.rMd,
        border: Border.all(color: AfriColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: labels.length == 1
                    ? Alignment.center
                    : Alignment(-1 + 2 * (index / (labels.length - 1)), 0),
                duration: AfriMotionSpec.base,
                curve: AfriMotionSpec.emphasized,
                child: Container(
                  width: itemWidth,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AfriColors.tealGlow,
                    borderRadius: AfriRadius.rSm,
                    boxShadow: AfriShadow.glow(AfriColors.teal, opacity: 0.22),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(i);
                        },
                        child: SizedBox(
                          height: 38,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AfriMotionSpec.base,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: i == index
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: i == index
                                    ? Colors.white
                                    : AfriColors.slate,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Gradient pill action button that floats above the glass nav bar.
class AfriFab extends StatelessWidget {
  const AfriFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.gradient = AfriColors.tealGlow,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AfriPressable(
        onTap: onPressed,
        scale: 0.94,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AfriRadius.pill),
            boxShadow: AfriShadow.glow(AfriColors.tealDark, opacity: 0.38),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: AfriSpace.xs),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms).scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        curve: Curves.easeOutBack);
  }
}

/// Screen header used by the list tabs: title, subtitle and an optional count.
class AfriListHeader extends StatelessWidget {
  const AfriListHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.count,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, AfriSpace.md, 20, AfriSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      if (count != null) ...[
                        const SizedBox(width: AfriSpace.xs),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AfriPill(label: '$count'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms)
        .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Soft badge for counts and tags.
class AfriPill extends StatelessWidget {
  const AfriPill({
    super.key,
    required this.label,
    this.color = AfriColors.teal,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: icon == null ? 10 : 8, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AfriRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
