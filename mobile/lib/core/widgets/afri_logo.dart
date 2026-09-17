import 'package:flutter/material.dart';

/// Official AfriOS mark — full asset, no extra circle/plate behind it.
class AfriLogo extends StatelessWidget {
  const AfriLogo({
    super.key,
    this.height = 120,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final double height;
  final BoxFit fit;

  /// Squircle clip; defaults to ~22% of height to match the asset.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? height * 0.22;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/afrios_logo.png',
        height: height,
        width: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        semanticLabel: 'AfriOS',
      ),
    );
  }
}
