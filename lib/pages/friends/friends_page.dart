import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend_models.dart';
import '../../models/shared_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/shared_session_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../widgets/page_header.dart';

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final activeRooms = ref.watch(activeSharedSessionsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: friendsAsync.when(
            data: (friends) => _FriendsBody(
              friends: friends,
              activeRooms: activeRooms,
              isDesktop: isDesktop,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Failed to load friends: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsBody extends ConsumerWidget {
  const _FriendsBody({
    required this.friends,
    required this.activeRooms,
    required this.isDesktop,
  });

  final List<FriendConnection> friends;
  final List<SharedStudySession> activeRooms;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();
    final filteredFriends = friends.where((friend) {
      if (query.isEmpty) return true;
      return friend.displayName.toLowerCase().contains(query) ||
          friend.email.toLowerCase().contains(query);
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 1320 : 900),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  20,
                  isDesktop ? 32 : 20,
                  0,
                ),
                child: _buildHeader(context, ref),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  16,
                  isDesktop ? 32 : 20,
                  0,
                ),
                child: _buildTopRow(ref),
              ),
            ),
            if (activeRooms.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 20,
                    20,
                    isDesktop ? 32 : 20,
                    0,
                  ),
                  child: _buildActiveRooms(context, activeRooms),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  20,
                  isDesktop ? 32 : 20,
                  14,
                ),
                child: Text(
                  friends.isEmpty
                      ? 'Build your study circle'
                      : '${filteredFriends.length} ${filteredFriends.length == 1 ? 'friend' : 'friends'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (friends.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 20,
                  ),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(28),
                    borderRadius: BorderRadius.circular(30),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_add_rounded,
                          size: 54,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Add a friend by email to start shared focus sessions and compare high-level stats only.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => _showAddFriendDialog(context, ref),
                          child: const Text('Add friend'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filteredFriends.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 20,
                  ),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(24),
                    child: const Text(
                      'No friends match that search.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  0,
                  isDesktop ? 32 : 20,
                  isDesktop ? 32 : 110,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 282,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _FriendCard(friend: filteredFriends[index]);
                  }, childCount: filteredFriends.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(
          child: PageHeader(title: 'Friends', showBackButton: false),
        ),
        FilledButton.icon(
          onPressed: () => _showAddFriendDialog(context, ref),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add friend'),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _scanQRCode(context),
          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTopRow(WidgetRef ref) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isDesktop ? 360 : double.infinity,
          child: TextField(
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).update(value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search friends',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            'Notes and focus names stay private. Friends only see summary stats.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRooms(
    BuildContext context,
    List<SharedStudySession> activeRooms,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live study rooms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < activeRooms.length; i++) ...[
            _ActiveRoomTile(room: activeRooms[i]),
            if (i < activeRooms.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddFriendDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    bool isBusy = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Add friend',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Friend email',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isBusy
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        debugPrint(
                          'FRIENDS UI: add friend submit start email=${controller.text.trim()}',
                        );
                        setState(() => isBusy = true);
                        try {
                          final user = await ref.read(authStateProvider.future);
                          debugPrint(
                            'FRIENDS UI: add friend auth resolved userId=${user?.uid}',
                          );
                          if (user == null) throw Exception('Not signed in.');
                          await ref
                              .read(authFriendServiceProvider)
                              .addFriendByEmail(
                                currentUserId: user.uid,
                                email: controller.text.trim(),
                              );
                          debugPrint(
                            'FRIENDS UI: add friend submit success email=${controller.text.trim()}',
                          );
                          if (context.mounted) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Friend added')),
                            );
                          }
                        } catch (e) {
                          debugPrint(
                            'FRIENDS UI: add friend submit error email=${controller.text.trim()} error=$e',
                          );
                          setState(() => isBusy = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        } finally {
                          debugPrint(
                            'FRIENDS UI: add friend submit end email=${controller.text.trim()}',
                          );
                        }
                      },
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scanQRCode(BuildContext context) async {
    final result = await context.push('/qr-scanner');
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Scanned: $result')));
    }
  }
}

class _ActiveRoomTile extends StatelessWidget {
  const _ActiveRoomTile({required this.room});

  final SharedStudySession room;

  @override
  Widget build(BuildContext context) {
    final names = room.participants.map((p) => p.displayName).join(', ');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.focusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(names, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              context.push(
                '/focus-session',
                extra: {
                  'title': room.focusTitle,
                  'reason': room.focusReason,
                  'dateId': room.hostFocusDateId,
                  'sharedSessionId': room.id,
                },
              );
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.friend});

  final FriendConnection friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(dailyFocusProvider);
    final focus = focusAsync.value;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                name: friend.displayName,
                photoUrl: friend.photoUrl,
                photoDataBase64: friend.photoDataBase64,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.email,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.surface,
                onSelected: (value) async {
                  if (value != 'remove') return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        'Remove friend',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Remove ${friend.displayName} from your friends list?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true || !context.mounted) return;
                  final user = await ref.read(authStateProvider.future);
                  if (user == null) return;
                  await ref
                      .read(authFriendServiceProvider)
                      .removeFriend(
                        currentUserId: user.uid,
                        friendId: friend.uid,
                      );
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'remove', child: Text('Remove friend')),
                ],
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _StatPill(
                label: 'Sessions',
                value: '${friend.stats.totalSessions}',
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: 'Minutes',
                value: '${friend.stats.totalMinutes}',
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: 'Avg rating',
                value: friend.averageRating == 0
                    ? 'N/A'
                    : friend.averageRating.toStringAsFixed(1),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'You can see consistency and volume here, but not private focus names or notes.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.86),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: focus == null
                      ? null
                      : () {
                          context.push(
                            '/focus-session',
                            extra: {
                              'title': focus.title,
                              'reason': focus.reason,
                              'dateId': focus.id,
                              'friendIds': [friend.uid],
                            },
                          );
                        },
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('Study together'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    this.photoUrl,
    this.photoDataBase64,
    this.radius = 20,
  });

  final String name;
  final String? photoUrl;
  final String? photoDataBase64;
  final double radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (photoDataBase64 != null && photoDataBase64!.isNotEmpty) {
      imageProvider = MemoryImage(base64Decode(photoDataBase64!));
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    if (imageProvider != null) {
      return CircleAvatar(radius: radius, backgroundImage: imageProvider);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.14),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
