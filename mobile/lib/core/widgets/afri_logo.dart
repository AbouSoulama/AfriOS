import 'package:flutter/material.dart';

class AfriLogo extends StatelessWidget {
  const AfriLogo({super.key, this.height = 120, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/afrios_logo.png',
      height: height,
      fit: fit,
      semanticLabel: 'AfriOS',
    );
  }
}
