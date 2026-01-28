import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/home/home_page.dart';
import '../pages/history/history_page.dart';
import '../pages/insights/insights_page.dart';
import '../pages/friends/friends_page.dart';
import '../providers/tab_provider.dart';
import '../theme/app_colors.dart';

class TabsBase extends ConsumerWidget {
  const TabsBase({super.key});

  static final List<Widget> _pages = const [
    HistoryPage(),
    HomePage(),
    InsightsPage(),
    FriendsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(tabsProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: tabIndex,
            children: _pages,
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _GlassTabBar(
                currentIndex: tabIndex,
                onTabSelected: (i) => ref.read(tabsProvider.notifier).setTab(i),
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

  const _GlassTabBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

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
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}