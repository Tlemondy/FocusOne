import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

class TabsBase extends ConsumerStatefulWidget {
  final Widget? child;

  const TabsBase({super.key, this.child});

  @override
  ConsumerState<TabsBase> createState() => _TabsBaseState();
}

class _TabsBaseState extends ConsumerState<TabsBase> {
  String? _lastPrimaryTabLocation;
  int _lastVerticalTabOrder = 0;
  int _verticalNavigationDirection = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final showsRoutedChild = widget.child != null;
    final effectiveTabIndex = _tabIndexForLocation(location);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final primaryTabLocation = _primaryTabLocation(location);
    final verticalTabOrder = _verticalTabOrderForLocation(location);

    if (_lastPrimaryTabLocation == null) {
      _lastPrimaryTabLocation = primaryTabLocation;
      _lastVerticalTabOrder = verticalTabOrder;
    } else if (_lastPrimaryTabLocation != primaryTabLocation) {
      _verticalNavigationDirection = verticalTabOrder > _lastVerticalTabOrder
          ? 1
          : -1;
      _lastPrimaryTabLocation = primaryTabLocation;
      _lastVerticalTabOrder = verticalTabOrder;
    }

    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  _buildDesktopRail(context, ref, effectiveTabIndex),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _buildDesktopContent(location),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (showsRoutedChild) {
      return widget.child!;
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          widget.child ?? const SizedBox.shrink(),
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

  Widget _buildDesktopContent(String location) {
    final child = widget.child ?? const SizedBox.shrink();
    final animationKey = ValueKey(_primaryTabLocation(location));

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      reverseDuration: AppMotion.medium,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      transitionBuilder: (transitionChild, animation) {
        final isIncoming = transitionChild.key == animationKey;
        final direction = _verticalNavigationDirection == 0
            ? 1
            : _verticalNavigationDirection;
        final incomingBegin = Offset(0, direction * 0.14);
        final outgoingEnd = Offset(0, direction * -0.14);
        final moveCurve = CurvedAnimation(
          parent: animation,
          curve: isIncoming ? AppMotion.emphasized : AppMotion.exit,
        );
        final opacityCurve = CurvedAnimation(
          parent: animation,
          curve: AppMotion.standard,
        );

        final offsetAnimation = Tween<Offset>(
          begin: isIncoming ? incomingBegin : Offset.zero,
          end: isIncoming ? Offset.zero : outgoingEnd,
        ).animate(moveCurve);

        final opacityAnimation = Tween<double>(
          begin: isIncoming ? 0.0 : 1,
          end: isIncoming ? 1 : 0.0,
        ).animate(opacityCurve);

        return FadeTransition(
          opacity: opacityAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: transitionChild,
          ),
        );
      },
      child: KeyedSubtree(key: animationKey, child: child),
    );
  }

  int _tabIndexForLocation(String location) {
    if (location.startsWith('/history') ||
        location.startsWith('/focus-detail') ||
        location.startsWith('/note-viewer')) {
      return 0;
    }
    if (location.startsWith('/home')) return 1;
    if (location.startsWith('/insights')) return 2;
    if (location.startsWith('/friends') || location.startsWith('/qr-scanner')) {
      return 3;
    }

    return 1;
  }

  String _primaryTabLocation(String location) {
    if (location.startsWith('/history') ||
        location.startsWith('/focus-detail') ||
        location.startsWith('/note-viewer')) {
      return '/history';
    }
    if (location.startsWith('/insights')) return '/insights';
    if (location.startsWith('/friends') || location.startsWith('/qr-scanner')) {
      return '/friends';
    }

    return '/home';
  }

  int _verticalTabOrderForLocation(String location) {
    final primaryTabLocation = _primaryTabLocation(location);

    return switch (primaryTabLocation) {
      '/home' => 0,
      '/history' => 1,
      '/insights' => 2,
      '/friends' => 3,
      _ => 0,
    };
  }

  void _handleTabSelection(BuildContext context, WidgetRef ref, int index) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final route = switch (index) {
      0 => '/history',
      1 => '/home',
      2 => '/insights',
      3 => '/friends',
      _ => '/home',
    };

    if (currentLocation != route) {
      context.go(route);
    }
  }

  Widget _buildDesktopRail(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    return SizedBox(
      width: 236,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Focus One',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Stay on one thing.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.68),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _buildNavItem(
              context,
              Icons.center_focus_strong_rounded,
              'Home',
              1,
              currentIndex,
              ref,
            ),
            _buildNavItem(
              context,
              Icons.history_rounded,
              'History',
              0,
              currentIndex,
              ref,
            ),
            _buildNavItem(
              context,
              Icons.insights_rounded,
              'Insights',
              2,
              currentIndex,
              ref,
            ),
            _buildNavItem(
              context,
              Icons.people_outline_rounded,
              'Friends',
              3,
              currentIndex,
              ref,
            ),
            const Spacer(),
            _buildRailFooter(ref),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.985,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: GestureDetector(
          onTap: () => _handleTabSelection(context, ref, index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(
                      alpha: isSelected ? 1 : 0.84,
                    ),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: Colors.white.withValues(
                        alpha: isSelected ? 1 : 0.82,
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailFooter(WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      child: AnimatedScale(
        scale: isSelected ? 1 : 0.96,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                offset: Offset(0, isSelected ? -0.03 : 0),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.5),
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.5),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
