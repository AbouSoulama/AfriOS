import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/afri_colors.dart';

class AfriOfflineBanner extends StatelessWidget {
  const AfriOfflineBanner({super.key, this.pendingCount = 0});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AfriSpace.md, AfriSpace.xs, AfriSpace.md, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: AfriColors.amberSoft,
          borderRadius: AfriRadius.rSm,
          border: Border.all(color: AfriColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AfriColors.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AfriRadius.xs),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 15, color: AfriColors.orange),
            ),
            const SizedBox(width: AfriSpace.xs),
            Expanded(
              child: Text(
                pendingCount > 0
                    ? 'Hors ligne — $pendingCount modification(s) en attente de synchronisation'
                    : 'Hors ligne — tes données seront synchronisées automatiquement',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AfriColors.ink,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.4, end: 0, curve: Curves.easeOutCubic);
  }
}
