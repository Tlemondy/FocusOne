import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/fade_in_animation.dart';
import '../../models/friend_models.dart';
import '../../models/shared_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/shared_session_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../widgets/page_header.dart';
import 'components/session_feedback_modal.dart';

class FocusSessionPage extends ConsumerStatefulWidget {
  const FocusSessionPage({
    super.key,
    required this.focusTitle,
    required this.focusReason,
    required this.focusDateId,
    this.sharedSessionId,
    this.preselectedFriendIds = const [],
  });

  final String focusTitle;
  final String? focusReason;
  final String focusDateId;
  final String? sharedSessionId;
  final List<String> preselectedFriendIds;

  @override
  ConsumerState<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends ConsumerState<FocusSessionPage> {
  static const List<int> _durations = [15, 25, 45, 60];

  final TextEditingController _sessionNoteController = TextEditingController();
  final TextEditingController _sharedNoteController = TextEditingController();
  final Set<String> _selectedFriendIds = <String>{};
  Timer? _ticker;
  int _timeTick = 0;
  int selectedDuration = 25;
  bool _isSavingSharedNote = false;
  bool _isCompletingSharedSession = false;

  @override
  void initState() {
    super.initState();
    _selectedFriendIds.addAll(widget.preselectedFriendIds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _timeTick++);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sessionNoteController.dispose();
    _sharedNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isWebDesktop = kIsWeb && isDesktop;

    _syncNoteController(activeSession);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeInAnimation(
            child: widget.sharedSessionId != null
                ? _buildSharedSessionScreen(
                    sessionId: widget.sharedSessionId!,
                    isWebDesktop: isWebDesktop,
                  )
                : activeSession == null
                ? _buildSetupScreen(
                    friendsAsync: friendsAsync,
                    isWebDesktop: isWebDesktop,
                  )
                : _buildSoloActiveScreen(
                    session: activeSession,
                    isWebDesktop: isWebDesktop,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen({
    required AsyncValue<List<FriendConnection>> friendsAsync,
    required bool isWebDesktop,
  }) {
    final body = friendsAsync.when(
      data: (friends) =>
          isWebDesktop ? _buildWebSetup(friends) : _buildMobileSetup(friends),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Failed to load friends: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );

    return body;
  }

  Widget _buildWebSetup(List<FriendConnection> friends) {
    final selectedFriends = friends
        .where((friend) => _selectedFriendIds.contains(friend.uid))
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeader(
                eyebrow: _selectedFriendIds.isEmpty
                    ? 'Solo focus'
                    : 'Shared study session',
                title: widget.focusTitle,
                description: widget.focusReason?.trim().isNotEmpty == true
                    ? widget.focusReason!
                    : 'Pick a duration, optionally bring friends in, and start immediately.',
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(32),
                      borderRadius: BorderRadius.circular(36),
                      opacity: 0.09,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedFriendIds.isEmpty
                                ? 'Stay solo or turn this into a live shared timer with your friends.'
                                : 'Everyone in the room will follow the same countdown and see the same shared note feed.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.82,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final duration in _durations)
                                _buildDurationTile(duration, large: true),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildFriendPicker(friends: friends, desktop: true),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPrimaryAction(
                                  label: _selectedFriendIds.isEmpty
                                      ? 'Start ${selectedDuration}m Session'
                                      : 'Start shared ${selectedDuration}m session',
                                  icon: _selectedFriendIds.isEmpty
                                      ? Icons.play_arrow_rounded
                                      : Icons.groups_rounded,
                                  onPressed: _startSession,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildSecondaryAction(
                                  label: 'Back',
                                  icon: Icons.arrow_back_rounded,
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildInfoCard(
                          title: 'Session plan',
                          rows: [
                            _InfoRow(label: 'Focus', value: widget.focusTitle),
                            _InfoRow(
                              label: 'Duration',
                              value: '$selectedDuration min',
                            ),
                            _InfoRow(
                              label: 'Mode',
                              value: _selectedFriendIds.isEmpty
                                  ? 'Solo timer'
                                  : 'Shared live room',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildInfoCard(
                          title: 'Participants',
                          rows: [
                            _InfoRow(
                              label: 'You',
                              value: 'Included automatically',
                            ),
                            _InfoRow(
                              label: 'Friends',
                              value: selectedFriends.isEmpty
                                  ? 'No friends selected'
                                  : selectedFriends
                                        .map((friend) => friend.displayName)
                                        .join(', '),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSetup(List<FriendConnection> friends) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              PageHeader(title: widget.focusTitle),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassContainer(
                padding: const EdgeInsets.all(28),
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose duration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.focusReason?.trim().isNotEmpty == true
                          ? widget.focusReason!
                          : 'Pick a duration and optionally invite friends into the same timer.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final duration in _durations)
                          _buildDurationTile(duration),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFriendPicker(friends: friends),
                    const SizedBox(height: 24),
                    _buildPrimaryAction(
                      label: _selectedFriendIds.isEmpty
                          ? 'Start session'
                          : 'Start shared session',
                      icon: _selectedFriendIds.isEmpty
                          ? Icons.play_arrow_rounded
                          : Icons.groups_rounded,
                      onPressed: _startSession,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSoloActiveScreen({
    required ActiveSessionState session,
    required bool isWebDesktop,
  }) {
    return isWebDesktop
        ? _buildWebSoloActive(session)
        : _buildMobileSoloActive(session);
  }

  Widget _buildWebSoloActive(ActiveSessionState session) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeader(
                eyebrow: session.isRunning
                    ? 'Session in progress'
                    : 'Session paused',
                title: widget.focusTitle,
                description: widget.focusReason?.trim().isNotEmpty == true
                    ? widget.focusReason!
                    : 'Stay with the task until the timer ends.',
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(34),
                      borderRadius: BorderRadius.circular(38),
                      opacity: 0.09,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSessionStatusRow(
                            durationMinutes: session.selectedDurationMinutes,
                            remainingSeconds: session.remainingSeconds,
                            isRunning: session.isRunning,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: _buildTimerDial(
                              remainingSeconds: session.remainingSeconds,
                              durationMinutes: session.selectedDurationMinutes,
                              isRunning: session.isRunning,
                              large: true,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPrimaryAction(
                                  label: session.isRunning ? 'Pause' : 'Resume',
                                  icon: session.isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  onPressed: session.isRunning
                                      ? () => ref
                                            .read(
                                              activeSessionProvider.notifier,
                                            )
                                            .pauseSession()
                                      : () => ref
                                            .read(
                                              activeSessionProvider.notifier,
                                            )
                                            .resumeSession(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildSecondaryAction(
                                  label: 'Finish',
                                  icon: Icons.stop_rounded,
                                  onPressed: _endSoloSession,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 5,
                    child: _buildPrivateNotesPanel(desktop: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSoloActive(ActiveSessionState session) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              PageHeader(title: widget.focusTitle),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassContainer(
                padding: const EdgeInsets.all(28),
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  children: [
                    _buildSessionStatusRow(
                      durationMinutes: session.selectedDurationMinutes,
                      remainingSeconds: session.remainingSeconds,
                      isRunning: session.isRunning,
                      compact: true,
                    ),
                    const SizedBox(height: 24),
                    _buildTimerDial(
                      remainingSeconds: session.remainingSeconds,
                      durationMinutes: session.selectedDurationMinutes,
                      isRunning: session.isRunning,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryAction(
                            label: session.isRunning ? 'Pause' : 'Resume',
                            icon: session.isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onPressed: session.isRunning
                                ? () => ref
                                      .read(activeSessionProvider.notifier)
                                      .pauseSession()
                                : () => ref
                                      .read(activeSessionProvider.notifier)
                                      .resumeSession(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSecondaryAction(
                            label: 'Finish',
                            icon: Icons.stop_rounded,
                            onPressed: _endSoloSession,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildPrivateNotesPanel(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedSessionScreen({
    required String sessionId,
    required bool isWebDesktop,
  }) {
    final sessionAsync = ref.watch(sharedSessionProvider(sessionId));
    final notesAsync = ref.watch(sharedSessionNotesProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const Center(
            child: Text(
              'Shared session not found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final remainingSeconds = session.remainingSecondsAt(DateTime.now());
        final currentUserId = ref.watch(authStateProvider).value?.uid;
        final hasCompleted =
            currentUserId != null &&
            session.completedParticipantIds.contains(currentUserId);

        return isWebDesktop
            ? _buildWebSharedActive(
                session: session,
                remainingSeconds: remainingSeconds,
                notesAsync: notesAsync,
                hasCompleted: hasCompleted,
              )
            : _buildMobileSharedActive(
                session: session,
                remainingSeconds: remainingSeconds,
                notesAsync: notesAsync,
                hasCompleted: hasCompleted,
              );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Failed to load shared session: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildWebSharedActive({
    required SharedStudySession session,
    required int remainingSeconds,
    required AsyncValue<List<SharedSessionNote>> notesAsync,
    required bool hasCompleted,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeader(
                eyebrow: 'Shared study room',
                title: session.focusTitle,
                description: session.focusReason?.trim().isNotEmpty == true
                    ? session.focusReason!
                    : 'Everyone in this room follows the same timer and shared note stream.',
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(34),
                      borderRadius: BorderRadius.circular(38),
                      opacity: 0.09,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSessionStatusRow(
                            durationMinutes: session.durationMinutes,
                            remainingSeconds: remainingSeconds,
                            isRunning: session.isRunning,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: _buildTimerDial(
                              remainingSeconds: remainingSeconds,
                              durationMinutes: session.durationMinutes,
                              isRunning: session.isRunning,
                              large: true,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 220,
                                child: _buildPrimaryAction(
                                  label: session.isPaused
                                      ? 'Resume for room'
                                      : 'Pause for room',
                                  icon: session.isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  onPressed: () =>
                                      _toggleSharedSession(session),
                                ),
                              ),
                              SizedBox(
                                width: 220,
                                child: _buildSecondaryAction(
                                  label: hasCompleted
                                      ? 'Saved'
                                      : remainingSeconds == 0
                                      ? 'Finish session'
                                      : 'End for room',
                                  icon: Icons.stop_rounded,
                                  onPressed: hasCompleted
                                      ? () {}
                                      : () => _endSharedSession(session),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildParticipantPanel(session),
                        const SizedBox(height: 18),
                        _buildSharedNotesPanel(
                          session: session,
                          notesAsync: notesAsync,
                          desktop: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSharedActive({
    required SharedStudySession session,
    required int remainingSeconds,
    required AsyncValue<List<SharedSessionNote>> notesAsync,
    required bool hasCompleted,
  }) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              PageHeader(title: session.focusTitle),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassContainer(
                padding: const EdgeInsets.all(28),
                borderRadius: BorderRadius.circular(30),
                child: Column(
                  children: [
                    _buildSessionStatusRow(
                      durationMinutes: session.durationMinutes,
                      remainingSeconds: remainingSeconds,
                      isRunning: session.isRunning,
                      compact: true,
                    ),
                    const SizedBox(height: 24),
                    _buildTimerDial(
                      remainingSeconds: remainingSeconds,
                      durationMinutes: session.durationMinutes,
                      isRunning: session.isRunning,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryAction(
                            label: session.isPaused ? 'Resume' : 'Pause',
                            icon: session.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            onPressed: () => _toggleSharedSession(session),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSecondaryAction(
                            label: hasCompleted ? 'Saved' : 'Finish',
                            icon: Icons.stop_rounded,
                            onPressed: hasCompleted
                                ? () {}
                                : () => _endSharedSession(session),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildParticipantPanel(session),
              const SizedBox(height: 18),
              _buildSharedNotesPanel(session: session, notesAsync: notesAsync),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendPicker({
    required List<FriendConnection> friends,
    bool desktop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Invite friends',
              style: TextStyle(
                fontSize: desktop ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          friends.isEmpty
              ? 'Add friends first to run synchronized study sessions.'
              : 'Choose one or more friends. If nobody is selected, this stays a private solo session.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.84),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        if (friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'No friends available yet.',
              style: TextStyle(color: Colors.white),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: friends.map((friend) {
              final isSelected = _selectedFriendIds.contains(friend.uid);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFriendIds.remove(friend.uid);
                    } else {
                      _selectedFriendIds.add(friend.uid);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected
                        ? null
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Avatar(
                        name: friend.displayName,
                        photoUrl: friend.photoUrl,
                        photoDataBase64: friend.photoDataBase64,
                        radius: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        friend.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPrivateNotesPanel({bool desktop = false}) {
    return GlassContainer(
      padding: EdgeInsets.all(desktop ? 28 : 24),
      borderRadius: BorderRadius.circular(desktop ? 30 : 28),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Private notes',
                style: TextStyle(
                  fontSize: desktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Only you can see these notes.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _sessionNoteController,
              maxLines: desktop ? 14 : 8,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Add notes about this session...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              onChanged: (value) {
                ref
                    .read(activeSessionProvider.notifier)
                    .updateSessionNote(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantPanel(SharedStudySession session) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(28),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participants',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: session.participants.map((participant) {
              final completed = session.completedParticipantIds.contains(
                participant.uid,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Avatar(
                      name: participant.displayName,
                      photoUrl: participant.photoUrl,
                      photoDataBase64: participant.photoDataBase64,
                      radius: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      participant.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (completed) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedNotesPanel({
    required SharedStudySession session,
    required AsyncValue<List<SharedSessionNote>> notesAsync,
    bool desktop = false,
  }) {
    return GlassContainer(
      padding: EdgeInsets.all(desktop ? 28 : 24),
      borderRadius: BorderRadius.circular(desktop ? 30 : 28),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.forum_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Shared notes',
                style: TextStyle(
                  fontSize: desktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Everyone in the session sees this feed, with names attached to each note.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sharedNoteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write a shared note...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _sendSharedNote(session),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _isSavingSharedNote
                    ? null
                    : () => _sendSharedNote(session),
                child: _isSavingSharedNote
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'No shared notes yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: desktop ? 420 : 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Avatar(
                                name: note.authorName,
                                photoUrl: note.authorPhotoUrl,
                                photoDataBase64: note.authorPhotoDataBase64,
                                radius: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                note.authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatNoteTime(note.createdAt),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            note.content,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: notes.length,
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Text(
              'Failed to load shared notes: $error',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader({
    required String eyebrow,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderBadge(label: eyebrow, icon: Icons.timelapse_rounded),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 720,
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textSecondary.withValues(alpha: 0.84),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            padding: const EdgeInsets.all(18),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStatusRow({
    required int durationMinutes,
    required int remainingSeconds,
    required bool isRunning,
    bool compact = false,
  }) {
    final progress = _sessionProgress(durationMinutes, remainingSeconds);
    final stateLabel = isRunning ? 'Running' : 'Paused';
    final progressLabel = '${(progress * 100).clamp(0, 100).round()}% complete';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildHeaderBadge(
          label: stateLabel,
          icon: isRunning
              ? Icons.play_circle_fill_rounded
              : Icons.pause_circle_filled_rounded,
        ),
        _buildHeaderBadge(
          label: '$durationMinutes min selected',
          icon: Icons.schedule_rounded,
        ),
        if (!compact)
          _buildHeaderBadge(
            label: progressLabel,
            icon: Icons.auto_graph_rounded,
          ),
      ],
    );
  }

  Widget _buildTimerDial({
    required int remainingSeconds,
    required int durationMinutes,
    required bool isRunning,
    bool large = false,
  }) {
    final progress = _sessionProgress(durationMinutes, remainingSeconds);
    final size = large ? 360.0 : 280.0;
    final status = isRunning ? 'Focus time' : 'Paused';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: large ? 14 : 12,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(
                progress > 0.2 ? AppColors.primary : Colors.orange,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatClock(remainingSeconds),
                style: TextStyle(
                  fontSize: large ? 76 : 64,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: -1.6,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                status,
                style: TextStyle(
                  fontSize: large ? 16 : 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationTile(int duration, {bool large = false}) {
    final isSelected = selectedDuration == duration;
    return InkWell(
      onTap: () => setState(() => selectedDuration = duration),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: large ? 170 : 142,
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: large ? 24 : 18,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.10),
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$duration',
              style: TextStyle(
                fontSize: large ? 38 : 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'minutes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.84)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<_InfoRow> rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < rows.length; i++) ...[
            _buildInfoRow(rows[i]),
            if (i < rows.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          row.value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBadge({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _startSession() async {
    if (_selectedFriendIds.isEmpty) {
      ref
          .read(activeSessionProvider.notifier)
          .startSession(widget.focusDateId, selectedDuration);
      return;
    }

    final currentProfile = await ref.read(currentPublicProfileProvider.future);
    final friends =
        ref.read(friendsProvider).value ?? const <FriendConnection>[];
    final invited = friends
        .where((friend) => _selectedFriendIds.contains(friend.uid))
        .toList();

    if (currentProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not ready yet. Try again.')),
        );
      }
      return;
    }

    final sessionId = await ref
        .read(sharedSessionServiceProvider)
        .createSharedSession(
          hostProfile: currentProfile,
          invitedFriends: invited,
          focusTitle: widget.focusTitle,
          focusReason: widget.focusReason,
          hostFocusDateId: widget.focusDateId,
          durationMinutes: selectedDuration,
        );

    if (!mounted) return;
    context.go(
      '/focus-session',
      extra: {
        'title': widget.focusTitle,
        'reason': widget.focusReason,
        'dateId': widget.focusDateId,
        'sharedSessionId': sessionId,
      },
    );
  }

  Future<void> _toggleSharedSession(SharedStudySession session) async {
    final service = ref.read(sharedSessionServiceProvider);
    if (session.isPaused) {
      await service.resumeSession(session);
    } else {
      await service.pauseSession(session);
    }
  }

  Future<void> _sendSharedNote(SharedStudySession session) async {
    final content = _sharedNoteController.text.trim();
    if (content.isEmpty || _isSavingSharedNote) return;

    final profile = await ref.read(currentPublicProfileProvider.future);
    if (profile == null) return;

    setState(() => _isSavingSharedNote = true);
    try {
      await ref
          .read(sharedSessionServiceProvider)
          .addNote(
            sessionId: session.id,
            authorId: profile.uid,
            authorName: profile.displayName,
            content: content,
            authorPhotoUrl: profile.photoUrl,
            authorPhotoDataBase64: profile.photoDataBase64,
            authorPhotoMimeType: profile.photoMimeType,
          );
      _sharedNoteController.clear();
    } finally {
      if (mounted) {
        setState(() => _isSavingSharedNote = false);
      }
    }
  }

  void _endSoloSession() {
    final activeSession = ref.read(activeSessionProvider);
    final sessionNote = activeSession?.sessionNote ?? '';
    _showFeedbackModal(
      initialNote: sessionNote,
      onSubmit: (rating, note) {
        ref
            .read(activeSessionProvider.notifier)
            .endSession(rating: rating, note: note);
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  void _endSharedSession(SharedStudySession session) {
    if (_isCompletingSharedSession) return;

    _showFeedbackModal(
      initialNote: '',
      onSubmit: (rating, note) async {
        final user = await ref.read(authStateProvider.future);
        final profile = await ref.read(currentPublicProfileProvider.future);
        if (user == null || profile == null) return;

        setState(() => _isCompletingSharedSession = true);
        try {
          await ref
              .read(sharedSessionServiceProvider)
              .completeSessionForUser(
                session: session,
                userId: user.uid,
                displayName: profile.displayName,
                rating: rating,
                privateNote: note,
              );
          if (mounted) {
            Navigator.pop(context);
          }
        } finally {
          if (mounted) {
            setState(() => _isCompletingSharedSession = false);
          }
        }
      },
    );
  }

  void _showFeedbackModal({
    required String initialNote,
    required FutureOr<void> Function(int rating, String? note) onSubmit,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SessionFeedbackModal(
            initialNote: initialNote,
            onSubmit: (rating, note) async {
              await onSubmit(rating, note);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SessionFeedbackModal(
        initialNote: initialNote,
        onSubmit: (rating, note) async {
          await onSubmit(rating, note);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  }

  void _syncNoteController(ActiveSessionState? activeSession) {
    final next = activeSession?.sessionNote ?? '';
    if (_sessionNoteController.text == next) return;
    _sessionNoteController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  double _sessionProgress(int durationMinutes, int remainingSeconds) {
    final totalSeconds = durationMinutes * 60;
    if (totalSeconds <= 0) return 0;
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  String _formatClock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatNoteTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
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
