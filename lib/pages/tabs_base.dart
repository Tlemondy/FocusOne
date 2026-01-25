import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_one/pages/home/home_page.dart' show HomePage;
import 'package:focus_one/pages/profile/profile_page.dart';
import 'package:focus_one/providers/tab_provider.dart' show tabsProvider;
import 'package:focus_one/utils/sizes_helper.dart' show displayWidth;
class TabsBase extends ConsumerStatefulWidget {
  const TabsBase({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TabsBaseState createState() => _TabsBaseState();
}

class _TabsBaseState extends ConsumerState<TabsBase> {
  final List<Widget> _widgetOptions = const [
    HomePage(),
    ProfilePage(),
  ];

  bool _isRailExpanded = false;

  @override
  Widget build(BuildContext context) {
    final width = displayWidth(context);
    final tabIndex = ref.watch(tabsProvider);
    // Future(() {
    //   ref.read(loadingProvider.notifier).state = false;
    // });
    return width < 600
        ? Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: tabIndex,
              children: _widgetOptions,
            ),
            bottomNavigationBar: BottomNavigationBar(
              elevation: 3,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: '',
                ),
              ],
              currentIndex: tabIndex,
              backgroundColor: Theme.of(context).colorScheme.onSecondary,
              onTap: (index) => ref.read(tabsProvider.notifier).state = index,
              selectedItemColor: Theme.of(context).colorScheme.onSurface,
              unselectedItemColor: Theme.of(context).colorScheme.secondary,
            ),
          )
        : Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _isRailExpanded = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _isRailExpanded = false;
                      });
                    },
                    child: NavigationRail(
                      extended: _isRailExpanded,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home),
                          selectedIcon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person),
                          selectedIcon: Icon(Icons.person),
                          label: Text('Account'),
                        ),
                      ],
                      selectedIndex: tabIndex,
                      onDestinationSelected: (index) {
                        ref.read(tabsProvider.notifier).state = index;
                      },
                    ),
                  ),
                  Expanded(
                    child: _widgetOptions[tabIndex],
                  ),
                ],
              ),
            ),
          );
  }
}