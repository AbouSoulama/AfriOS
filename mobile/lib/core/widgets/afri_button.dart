import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/afri_colors.dart';
import 'afri_premium.dart';

enum AfriButtonVariant { primary, secondary, ghost, soft, gold, danger }

enum AfriButtonSize { regular, compact }

class AfriButton extends StatelessWidget {
  const AfriButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AfriButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.size = AfriButtonSize.regular,
  });

  final String label;
  final VoidCallback? onPressed;
  final AfriButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final AfriButtonSize size;

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final spec = _spec();
    final vertical = size == AfriButtonSize.regular ? 17.0 : 12.0;
    final horizontal = size == AfriButtonSize.regular ? 24.0 : 18.0;
    final fontSize = size == AfriButtonSize.regular ? 15.5 : 14.0;

    final content = isLoading
        ? SizedBox(
            height: 21,
            width: 21,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              strokeCap: StrokeCap.round,
              color: spec.foreground,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: spec.foreground),
                const SizedBox(width: AfriSpace.xs),
              ],
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  color: spec.foreground,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          );

    Widget body = AnimatedOpacity(
      opacity: _disabled && !isLoading ? 0.45 : 1,
      duration: AfriMotionSpec.fast,
      child: Container(
        padding:
            EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
        decoration: BoxDecoration(
          gradient: spec.gradient,
          color: spec.color,
          borderRadius: AfriRadius.rMd,
          border: spec.border,
          boxShadow: _disabled ? null : spec.shadow,
        ),
        child: Center(child: content),
      ),
    );

    if (expand) body = SizedBox(width: double.infinity, child: body);

    return AfriPressable(
      onTap: _disabled ? null : onPressed,
      scale: 0.975,
      child: body,
    );
  }

  _ButtonSpec _spec() {
    switch (variant) {
      case AfriButtonVariant.primary:
        return _ButtonSpec(
          gradient: AfriColors.tealGlow,
          foreground: Colors.white,
          shadow: AfriShadow.glow(AfriColors.teal, opacity: 0.30),
        );
      case AfriButtonVariant.gold:
        return _ButtonSpec(
          gradient: AfriColors.goldGlow,
          foreground: AfriColors.ink,
          shadow: AfriShadow.glow(AfriColors.gold, opacity: 0.32),
        );
      case AfriButtonVariant.danger:
        return _ButtonSpec(
          color: AfriColors.error,
          foreground: Colors.white,
          shadow: AfriShadow.glow(AfriColors.error, opacity: 0.26),
        );
      case AfriButtonVariant.secondary:
        return _ButtonSpec(
          color: Colors.white.withValues(alpha: 0.10),
          foreground: Colors.white,
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        );
      case AfriButtonVariant.soft:
        return _ButtonSpec(
          color: Colors.white,
          foreground: AfriColors.ink,
          border: Border.all(color: AfriColors.mistDeep),
          shadow: AfriShadow.card,
        );
      case AfriButtonVariant.ghost:
        return const _ButtonSpec(
          color: Colors.transparent,
          foreground: AfriColors.tealDark,
        );
    }
  }
}

class _ButtonSpec {
  const _ButtonSpec({
    required this.foreground,
    this.gradient,
    this.color,
    this.border,
    this.shadow,
  });

  final Color foreground;
  final Gradient? gradient;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
}
