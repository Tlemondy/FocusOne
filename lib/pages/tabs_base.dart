import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/home/home_page.dart';
import '../pages/history/history_page.dart';
import '../pages/insights/insights_page.dart';
import '../pages/friends/friends_page.dart';
import '../providers/tab_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

class TabsBase extends ConsumerWidget {
  final Widget? child;

  const TabsBase({super.key, this.child});

  static final List<Widget> _pages = const [
    HistoryPage(),
    HomePage(),
    InsightsPage(),
    FriendsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(tabsProvider);
    final location = GoRouterState.of(context).uri.toString();
    final showsRoutedChild = child != null && location != '/';
    final effectiveTabIndex = _tabIndexForLocation(location, tabIndex);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 280,
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'Focus One',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildNavItem(
                      context,
                      Icons.center_focus_strong_rounded,
                      'Home',
                      1,
                      effectiveTabIndex,
                      ref,
                    ),
                    _buildNavItem(
                      context,
                      Icons.history_rounded,
                      'History',
                      0,
                      effectiveTabIndex,
                      ref,
                    ),
                    _buildNavItem(
                      context,
                      Icons.insights_rounded,
                      'Insights',
                      2,
                      effectiveTabIndex,
                      ref,
                    ),
                    _buildNavItem(
                      context,
                      Icons.people_outline_rounded,
                      'Friends',
                      3,
                      effectiveTabIndex,
                      ref,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.red.shade400,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: showsRoutedChild
                  ? child!
                  : IndexedStack(index: tabIndex, children: _pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: tabIndex, children: _pages),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _GlassTabBar(
                currentIndex: effectiveTabIndex,
                onTabSelected: (i) => _handleTabSelection(context, ref, i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _tabIndexForLocation(String location, int fallbackIndex) {
    if (location.startsWith('/focus-detail') ||
        location.startsWith('/note-viewer')) {
      return 0;
    }

    return fallbackIndex;
  }

  void _handleTabSelection(BuildContext context, WidgetRef ref, int index) {
    ref.read(tabsProvider.notifier).setTab(index);
    if (GoRouterState.of(context).uri.toString() != '/') {
      context.go('/');
    }
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int currentIndex,
    WidgetRef ref,
  ) {
    final isSelected = index == currentIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => _handleTabSelection(context, ref, index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _GlassTabBar({required this.currentIndex, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.history_rounded, 'History'),
      (Icons.center_focus_strong_rounded, 'Home'),
      (Icons.insights_rounded, 'Insights'),
      (Icons.people_outline_rounded, 'Friends'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / 4;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: tabWidth * currentIndex + 8,
                    top: 8,
                    width: tabWidth - 16,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (index) {
                      final icon = items[index].$1;
                      final label = items[index].$2;
                      final isSelected = index == currentIndex;

                      return Expanded(
                        child: _GlassTabItem(
                          icon: icon,
                          label: label,
                          isSelected: isSelected,
                          onTap: () => onTabSelected(index),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.5),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
