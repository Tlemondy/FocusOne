import 'package:flutter_riverpod/flutter_riverpod.dart';

final tabsProvider = NotifierProvider<TabsNotifier, int>(TabsNotifier.new);

class TabsNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}