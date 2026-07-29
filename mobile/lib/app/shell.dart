import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/database/sync_service.dart';
import '../core/theme/afri_colors.dart';

class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const _navItems = [
  _NavItem(
    route: '/home',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
    label: 'Accueil',
  ),
  _NavItem(
    route: '/invoices',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
    label: 'Factures',
  ),
  _NavItem(
    route: '/clients',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    label: 'Clients',
  ),
  _NavItem(
    route: '/stock',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2_rounded,
    label: 'Stock',
  ),
  _NavItem(
    route: '/ai',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
    label: 'IA',
  ),
];

/// Bottom inset for scrollable tab content. With [AppShell.extendBody] off,
/// only a light breathing room under the last tile is needed (FAB clearance).
double shellBottomClearance(BuildContext context) {
  return MediaQuery.of(context).padding.bottom + 28;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = _indexFromLocation(path);

    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) async {
      final wasOffline = prev?.value == false;
      final nowOnline = next.value == true;
      if (wasOffline && nowOnline) {
        final sync = await ref.read(syncServiceProvider.future);
        final n = await sync.syncIfOnline(true);
        ref.read(pendingOpsTickProvider.notifier).state++;
        if (n > 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$n opération(s) synchronisée(s)')),
          );
        }
      }
    });

    // Do NOT wrap [child] in AnimatedSwitcher / KeyedSubtree: GoRouter's
    // ShellRoute already owns those elements and re-parenting them triggers
    // `_elements.contains(element)` assertions on tab / auth transitions.
    //
    // extendBody must stay false — otherwise list tiles paint under the
    // floating glass nav and remain visible through / below it.
    return Scaffold(
      backgroundColor: AfriColors.mist,
      body: child,
      bottomNavigationBar: ColoredBox(
        color: AfriColors.mist,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AfriRadius.xl),
                border: Border.all(color: AfriColors.line),
                boxShadow: AfriShadow.lifted,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AfriRadius.xl),
                child: _AfriNavBar(
                  index: index,
                  onSelect: (i) {
                    if (i == index) return;
                    HapticFeedback.selectionClick();
                    context.go(_navItems[i].route);
                  },
                ),
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 450.ms)
          .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
    );
  }

  int _indexFromLocation(String path) {
    for (var i = 0; i < _navItems.length; i++) {
      if (path.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }
}

class _AfriNavBar extends StatelessWidget {
  const _AfriNavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / _navItems.length;
          return Stack(
            children: [
              AnimatedAlign(
                alignment:
                    Alignment(-1 + 2 * (index / (_navItems.length - 1)), 0),
                duration: AfriMotionSpec.base,
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: slot,
                  child: Center(
                    child: Container(
                      width: slot - 14,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AfriColors.tealSoft.withValues(alpha: 0.85),
                        borderRadius: AfriRadius.rSm,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _navItems.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: _navItems[i],
                        selected: i == index,
                        onTap: () => onSelect(i),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AfriColors.tealDark : AfriColors.slateLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: AfriMotionSpec.base,
            curve: Curves.easeOutBack,
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: AfriMotionSpec.base,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

/// Compact brand mark for app bars.
class AfriBrandMark extends StatelessWidget {
  const AfriBrandMark({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Text(
      'AfriOS',
      style: GoogleFonts.sora(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: light ? Colors.white : AfriColors.ink,
      ),
    );
  }
}
