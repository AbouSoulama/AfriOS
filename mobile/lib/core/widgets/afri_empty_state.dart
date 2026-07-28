import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/afri_colors.dart';
import 'afri_button.dart';

class AfriEmptyState extends StatelessWidget {
  const AfriEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AfriSpace.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AfriColors.teal.withValues(alpha: 0.16),
                          AfriColors.teal.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: AfriColors.tealSoft, width: 1.4),
                      boxShadow: AfriShadow.card,
                    ),
                  ),
                  Icon(icon, size: 36, color: AfriColors.teal),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 600.ms,
                ),
            const SizedBox(height: AfriSpace.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AfriSpace.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AfriSpace.lg),
              AfriButton(
                  label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}
