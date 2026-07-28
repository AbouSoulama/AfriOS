import 'package:flutter/material.dart';

import '../theme/afri_colors.dart';

class AfriStatusBadge extends StatelessWidget {
  const AfriStatusBadge({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AfriRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _resolve(String s) {
    switch (s) {
      case 'paid':
        return ('Payée', AfriColors.success);
      case 'sent':
        return ('En attente', AfriColors.navy);
      case 'overdue':
        return ('En retard', AfriColors.orange);
      case 'draft':
        return ('Brouillon', AfriColors.slate);
      case 'cancelled':
        return ('Annulée', AfriColors.error);
      default:
        return (s, AfriColors.slate);
    }
  }
}
