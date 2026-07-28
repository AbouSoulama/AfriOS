import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/afri_colors.dart';
import 'afri_amount.dart';
import 'afri_premium.dart';
import 'afri_status_badge.dart';

class AfriKPICard extends StatelessWidget {
  const AfriKPICard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.isAmount = false,
    this.trend,
    this.featured = false,
    this.onTap,
    this.accent = AfriColors.teal,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final bool isAmount;
  final double? trend;
  final bool featured;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fg = featured ? Colors.white : AfriColors.ink;
    final muted =
        featured ? Colors.white.withValues(alpha: 0.80) : AfriColors.slate;
    final numberStyle = GoogleFonts.sora(
      fontSize: 27,
      fontWeight: FontWeight.w800,
      color: fg,
      letterSpacing: -1,
      height: 1.1,
    );

    final card = Container(
      padding: const EdgeInsets.all(AfriSpace.md),
      decoration: BoxDecoration(
        gradient: featured ? AfriColors.heroGradient : null,
        color: featured ? null : Colors.white,
        borderRadius: AfriRadius.rLg,
        border: featured ? null : Border.all(color: AfriColors.line),
        boxShadow: featured
            ? AfriShadow.glow(AfriColors.tealDeep, opacity: 0.35)
            : AfriShadow.card,
      ),
      child: Stack(
        children: [
          if (featured)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AfriColors.tealBright.withValues(alpha: 0.35),
                      AfriColors.tealBright.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: featured
                            ? Colors.white.withValues(alpha: 0.16)
                            : accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AfriRadius.xs),
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: featured ? Colors.white : accent,
                      ),
                    ),
                    const SizedBox(width: AfriSpace.xs),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AfriSpace.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: isAmount
                    ? AfriAnimatedAmount(
                        amount: double.tryParse(value.replaceAll(' ', '')) ?? 0,
                        style: numberStyle,
                      )
                    : Text(value, style: numberStyle),
              ),
              if (trend != null) ...[
                const SizedBox(height: AfriSpace.xs),
                Row(
                  children: [
                    Icon(
                      trend! >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: featured
                          ? Colors.white.withValues(alpha: 0.9)
                          : (trend! >= 0
                              ? AfriColors.success
                              : AfriColors.error),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: featured
                            ? Colors.white.withValues(alpha: 0.9)
                            : (trend! >= 0
                                ? AfriColors.success
                                : AfriColors.error),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs mois dernier',
                      style: GoogleFonts.dmSans(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return AfriPressable(onTap: onTap, child: card)
        .animate()
        .fadeIn(duration: 420.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Deterministic avatar gradient so each client keeps a stable identity colour.
LinearGradient _avatarGradient(String seed) {
  const palettes = [
    [AfriColors.tealBright, AfriColors.tealDark],
    [AfriColors.goldBright, AfriColors.gold],
    [Color(0xFF7F8CF0), AfriColors.violet],
    [Color(0xFF48C6A0), AfriColors.green],
    [Color(0xFFFF9E6B), AfriColors.orange],
  ];
  final index = seed.isEmpty ? 0 : seed.codeUnitAt(0) % palettes.length;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: palettes[index],
  );
}

class AfriClientTile extends StatelessWidget {
  const AfriClientTile({
    super.key,
    required this.name,
    this.phone,
    this.amountDue,
    this.onTap,
  });

  final String name;
  final String? phone;
  final double? amountDue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasDue = amountDue != null && amountDue! > 0;

    return AfriPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AfriRadius.rLg,
          border: Border.all(color: AfriColors.line),
          boxShadow: AfriShadow.subtle,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _avatarGradient(name),
                borderRadius: AfriRadius.rSm,
              ),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AfriSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AfriColors.ink,
                    ),
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AfriColors.slateLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDue)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AfriAmount(
                    amount: amountDue!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    color: AfriColors.orange,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'à recouvrer',
                    style:
                        TextStyle(fontSize: 10.5, color: AfriColors.slateLight),
                  ),
                ],
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AfriColors.slateLight,
              ),
          ],
        ),
      ),
    );
  }
}

class AfriInvoiceTile extends StatelessWidget {
  const AfriInvoiceTile({
    super.key,
    required this.number,
    required this.clientName,
    required this.total,
    required this.status,
    this.onTap,
    this.subtitle,
    this.leadingIcon,
  });

  final String number;
  final String clientName;
  final double total;
  final String status;
  final VoidCallback? onTap;
  final String? subtitle;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final accent = switch (status) {
      'paid' => AfriColors.success,
      'overdue' => AfriColors.orange,
      'sent' => AfriColors.navy,
      _ => AfriColors.slateLight,
    };

    return AfriPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AfriRadius.rLg,
          border: Border.all(color: AfriColors.line),
          boxShadow: AfriShadow.subtle,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 58,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AfriRadius.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 14, 13),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(AfriRadius.xs),
                        ),
                        child: Icon(leadingIcon, size: 19, color: accent),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName.isEmpty
                                ? number
                                : '$number · $clientName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: AfriColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              AfriAmount(
                                amount: total,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                color: AfriColors.slate,
                              ),
                              if (subtitle != null) ...[
                                const Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    color: AfriColors.slateLight,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AfriColors.slateLight,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AfriSpace.xs),
                    AfriStatusBadge(status: status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AfriChatBubble extends StatelessWidget {
  const AfriChatBubble(
      {super.key, required this.message, required this.isUser});

  final String message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.symmetric(vertical: 5, horizontal: AfriSpace.md),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isUser ? AfriColors.tealGlow : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AfriRadius.md),
            topRight: const Radius.circular(AfriRadius.md),
            bottomLeft: Radius.circular(isUser ? AfriRadius.md : 6),
            bottomRight: Radius.circular(isUser ? 6 : AfriRadius.md),
          ),
          border: isUser ? null : Border.all(color: AfriColors.line),
          boxShadow: isUser
              ? AfriShadow.glow(AfriColors.teal, opacity: 0.20)
              : AfriShadow.subtle,
        ),
        child: Text(
          message,
          style: GoogleFonts.dmSans(
            color: isUser ? Colors.white : AfriColors.ink,
            height: 1.45,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Three-dot "assistant is thinking" indicator.
class AfriTypingBubble extends StatelessWidget {
  const AfriTypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.symmetric(vertical: 5, horizontal: AfriSpace.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AfriRadius.md),
            topRight: Radius.circular(AfriRadius.md),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(AfriRadius.md),
          ),
          border: Border.all(color: AfriColors.line),
          boxShadow: AfriShadow.subtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AfriColors.teal,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                      delay: (i * 160).ms,
                    )
                    .fadeIn(duration: 400.ms)
                    .then()
                    .fadeOut(duration: 400.ms),
              ),
          ],
        ),
      ),
    );
  }
}
