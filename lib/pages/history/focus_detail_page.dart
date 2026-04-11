import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/tab_provider.dart';
import '../../models/focus_session.dart';
import 'history_page.dart';

final focusSessionsProvider = FutureProvider.family<List<FocusSession>, String>(
  (ref, dateId) async {
    final authState = await ref.watch(authStateProvider.future);
    if (authState == null) return [];

    final service = ref.read(sessionServiceProvider);
    return await service.getTodaySessions(authState.uid, dateId);
  },
);

class FocusDetailPage extends ConsumerStatefulWidget {
  final String dateId;
  final String title;
  final String? reason;
  final DateTime date;

  const FocusDetailPage({
    super.key,
    required this.dateId,
    required this.title,
    required this.reason,
    required this.date,
  });

  @override
  ConsumerState<FocusDetailPage> createState() => _FocusDetailPageState();
}

class _FocusDetailPageState extends ConsumerState<FocusDetailPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(focusSessionsProvider(widget.dateId));
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isWebDesktop = kIsWeb && isDesktop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: sessionsAsync.when(
            data: (sessions) => isWebDesktop
                ? _buildWebDetail(context, sessions)
                : _buildMobileDetail(context, sessions),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebDetail(BuildContext context, List<FocusSession> sessions) {
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final completedSessions = sessions
        .where((s) => s.status == 'completed')
        .length;
    final notesCount = sessions
        .where((s) => (s.note ?? '').trim().isNotEmpty)
        .length;
    final averageRating = _averageRating(sessions);

    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -40,
          child: _buildAmbientGlow(
            size: 280,
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          left: -80,
          bottom: -120,
          child: _buildAmbientGlow(
            size: 320,
            colors: [
              AppColors.secondary.withValues(alpha: 0.16),
              Colors.transparent,
            ],
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, web: true),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroCard(
                              sessions: sessions,
                              totalMinutes: totalMinutes,
                              completedSessions: completedSessions,
                              notesCount: notesCount,
                              averageRating: averageRating,
                            ),
                            const SizedBox(height: 18),
                            _buildSessionSection(context, sessions, web: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildInsightPanel(
                              title: 'Summary',
                              children: [
                                _buildSideStat(
                                  'Total Sessions',
                                  '${sessions.length}',
                                  'logged for this focus',
                                ),
                                const SizedBox(height: 14),
                                _buildSideStat(
                                  'Completion Rate',
                                  sessions.isEmpty
                                      ? '0%'
                                      : '${((completedSessions / sessions.length) * 100).round()}%',
                                  'sessions finished fully',
                                ),
                                const SizedBox(height: 14),
                                _buildSideStat(
                                  'Average Rating',
                                  averageRating == 0
                                      ? 'N/A'
                                      : averageRating.toStringAsFixed(1),
                                  'based on rated sessions',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildInsightPanel(
                              title: 'Actions',
                              children: [
                                _buildActionRow(
                                  icon: Icons.delete_outline_rounded,
                                  title: 'Delete This Focus',
                                  detail:
                                      'Remove the focus and every session saved under it.',
                                  danger: true,
                                  onTap: () => _deleteFocus(context),
                                ),
                                const SizedBox(height: 12),
                                _buildActionRow(
                                  icon: Icons.arrow_back_rounded,
                                  title: 'Back To History',
                                  detail:
                                      'Return to the history browser with the tabs still visible.',
                                  onTap: () => context.pop(),
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
        ),
      ],
    );
  }

  Widget _buildMobileDetail(BuildContext context, List<FocusSession> sessions) {
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final completedSessions = sessions
        .where((s) => s.status == 'completed')
        .length;
    final notesCount = sessions
        .where((s) => (s.note ?? '').trim().isNotEmpty)
        .length;
    final averageRating = _averageRating(sessions);

    return Column(
      children: [
        _buildHeader(context, web: false),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(
                  sessions: sessions,
                  totalMinutes: totalMinutes,
                  completedSessions: completedSessions,
                  notesCount: notesCount,
                  averageRating: averageRating,
                ),
                const SizedBox(height: 18),
                _buildSessionSection(context, sessions, web: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required bool web}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: web ? 8 : 20),
      child: Row(
        children: [
          _buildChromeButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatLongDate(widget.date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Focus History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _buildChromeButton(
            icon: Icons.delete_outline_rounded,
            onTap: _isDeleting ? null : () => _deleteFocus(context),
            danger: true,
            loading: _isDeleting,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required List<FocusSession> sessions,
    required int totalMinutes,
    required int completedSessions,
    required int notesCount,
    required double averageRating,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: BorderRadius.circular(34),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderBadge(
                icon: Icons.schedule_rounded,
                label: '$totalMinutes minutes',
              ),
              _buildHeaderBadge(
                icon: Icons.stacked_bar_chart_rounded,
                label: '${sessions.length} sessions',
              ),
              _buildHeaderBadge(
                icon: Icons.notes_rounded,
                label: '$notesCount notes',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.08,
              letterSpacing: -1.0,
            ),
          ),
          if (widget.reason != null && widget.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                widget.reason!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.65,
                  color: AppColors.textSecondary.withValues(alpha: 0.84),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wrapCards = constraints.maxWidth < 720;
              final cards = [
                _summaryMetric(
                  'Finished',
                  '$completedSessions',
                  'completed sessions',
                ),
                _summaryMetric(
                  'Rated',
                  averageRating == 0 ? 'N/A' : averageRating.toStringAsFixed(1),
                  'average quality',
                ),
                _summaryMetric('Notes', '$notesCount', 'sessions with notes'),
              ];

              if (wrapCards) {
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: cards
                      .map((card) => SizedBox(width: 220, child: card))
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, String detail) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSection(
    BuildContext context,
    List<FocusSession> sessions, {
    required bool web,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(32),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Session Timeline',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length} entries',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (sessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                'No sessions recorded for this focus yet.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary.withValues(alpha: 0.82),
                ),
              ),
            )
          else if (web)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1080 ? 2 : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 250,
                  ),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) =>
                      _buildSessionCard(context, sessions[index]),
                );
              },
            )
          else
            Column(
              children: [
                for (int i = 0; i < sessions.length; i++) ...[
                  _buildSessionCard(context, sessions[i]),
                  if (i < sessions.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, FocusSession session) {
    final timeStr = _formatTime(session.startedAt);
    final endedAt = _formatTime(session.endedAt);
    final isCompleted = session.status == 'completed';
    final note = session.note?.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Ended Early',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$timeStr - $endedAt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _inlineMetric(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: '${session.durationMinutes} min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inlineMetric(
                  icon: Icons.star_outline_rounded,
                  label: 'Rating',
                  value: session.rating == null ? 'N/A' : '${session.rating}/5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (session.rating != null)
            Row(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    index < session.rating!
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          if (session.rating != null) const SizedBox(height: 16),
          if (note != null && note.isNotEmpty)
            InkWell(
              onTap: () => context.push(
                '/note-viewer',
                extra: {
                  'note': note,
                  'sessionId': session.id,
                  'focusDateId': widget.dateId,
                },
              ),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.86,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'No note saved for this session.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.68),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inlineMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPanel({
    required String title,
    required List<Widget> children,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(30),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSideStat(String label, String value, String caption) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: danger
              ? Colors.red.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: danger
                ? Colors.red.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: danger ? Colors.red.shade300 : Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: danger ? Colors.red.shade300 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChromeButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool danger = false,
    bool loading = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger
            ? Colors.red.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: danger
              ? Colors.red.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: danger ? Colors.red.shade300 : Colors.white),
      ),
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow({
    required double size,
    required List<Color> colors,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }

  double _averageRating(List<FocusSession> sessions) {
    final ratedSessions = sessions
        .where((session) => session.rating != null)
        .toList();
    if (ratedSessions.isEmpty) return 0;

    final total = ratedSessions.fold<int>(
      0,
      (sum, session) => sum + session.rating!,
    );
    return total / ratedSessions.length;
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatLongDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  Future<void> _deleteFocus(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11192D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete Focus History?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete "${widget.title}" and every saved session linked to it?',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red.shade300),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDeleting = true);

    try {
      final authState = await ref.read(authStateProvider.future);
      if (authState == null) return;

      final service = ref.read(firestoreServiceProvider);
      await service.deleteCompletedFocus(authState.uid, widget.dateId);

      ref.invalidate(completedFocusesProvider);
      ref.invalidate(focusSessionsProvider(widget.dateId));

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('History item deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/history');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete focus: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
