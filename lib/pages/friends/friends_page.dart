import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../widgets/page_header.dart';

final hasFriendsProvider = NotifierProvider<HasFriendsNotifier, bool>(HasFriendsNotifier.new);
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class HasFriendsNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void toggle() => state = !state;
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void update(String query) => state = query;
}

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFriends = ref.watch(hasFriendsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: hasFriends ? _buildFriendsList(context, ref, isDesktop) : _buildEmptyState(context, isDesktop),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        Row(
          children: [
            const Expanded(child: PageHeader(title: 'Friends', showBackButton: false)),
            Padding(
              padding: EdgeInsets.only(right: isDesktop ? 40 : 24, top: 24),
              child: IconButton(
                onPressed: () => _scanQRCode(context),
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
              child: GlassContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No friends yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan a QR code to add friends',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsList(BuildContext context, WidgetRef ref, bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 104,
              floating: false,
              pinned: false,
              snap: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Row(
                    children: [
                      const Expanded(child: PageHeader(title: 'Friends', showBackButton: false)),
                      Padding(
                        padding: EdgeInsets.only(right: isDesktop ? 40 : 24, top: 24),
                        child: IconButton(
                          onPressed: () => _scanQRCode(context),
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSearchBar(ref),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + (isDesktop ? 40 : 100)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search friends...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  void _scanQRCode(BuildContext context) async {
    final result = await context.push('/qr-scanner');
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned: $result')),
      );
    }
  }
}
