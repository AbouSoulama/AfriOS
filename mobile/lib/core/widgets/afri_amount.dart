import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/afri_colors.dart';

class AfriAmount extends StatelessWidget {
  const AfriAmount({
    super.key,
    required this.amount,
    this.currency = 'FCFA',
    this.style,
    this.color,
  });

  final num amount;
  final String currency;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,###', 'fr_FR').format(amount);
    return Text(
      '$formatted $currency',
      style: (style ?? Theme.of(context).textTheme.titleLarge)?.copyWith(
        fontWeight: FontWeight.w800,
        color: color ?? AfriColors.ink,
      ),
    );
  }
}
