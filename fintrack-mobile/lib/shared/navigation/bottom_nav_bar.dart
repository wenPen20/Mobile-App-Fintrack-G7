// lib/shared/navigation/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';
import 'package:fintrack_mobile/core/constants/app_text_styles.dart';

/// Describes each tab in the bottom nav bar.
class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });
}

const List<_NavItem> _navItems = [
  _NavItem(
    label: 'Dashboard',
    route: '/home',
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
  ),
  _NavItem(
    label: 'Transactions',
    route: '/transactions',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
  ),
  _NavItem(
    label: 'Add',
    route: '/add_transaction',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
  ),
  _NavItem(
    label: 'Budget',
    route: '/budget',
    icon: Icons.pie_chart_outline_rounded,
    activeIcon: Icons.pie_chart_rounded,
  ),
  _NavItem(
    label: 'Profile',
    route: '/profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

/// Main bottom navigation bar widget for switching shell tabs.
class FintrackBottomNavBar extends StatelessWidget {
  /// The route location of the currently active shell branch.
  final String currentLocation;

  const FintrackBottomNavBar({
    super.key,
    required this.currentLocation,
  });

  int _selectedIndex() {
    for (int i = 0; i < _navItems.length; i++) {
      if (currentLocation.startsWith(_navItems[i].route)) return i;
    }
    return 0; // default to Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = index == selectedIndex;

              if (item.route == '/add_transaction') {
                return Expanded(
                  child: _CenterAddButton(onTap: () => context.push(item.route)),
                );
              }

              return Expanded(
                child: _NavBarItem(
                  item: item,
                  isActive: isActive,
                  onTap: () {
                    if (!isActive) {
                      context.go(item.route);
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation bar item component.
class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                size: 24,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center action button component launching the add transaction screen.
class _CenterAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
