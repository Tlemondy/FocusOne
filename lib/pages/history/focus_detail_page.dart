import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../models/focus_session.dart';

final focusSessionsProvider = FutureProvider.family<List<FocusSession>, String>((ref, dateId) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];
  
  final service = ref.read(sessionServiceProvider);
  return await service.getTodaySessions(authState.uid, dateId);
});

class FocusDetailPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(focusSessionsProvider(dateId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFocusInfo(),
                      const SizedBox(height: 24),
                      sessionsAsync.when(
                        data: (sessions) => _buildSessions(sessions),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_monthName(date.month)} ${date.day}, ${date.year}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (reason != null) ...[
            const SizedBox(height: 12),
            Text(
              reason!,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessions(List<FocusSession> sessions) {
    if (sessions.isEmpty) {
      return GlassContainer(
        child: Center(
          child: Text(
            'No sessions recorded',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessions (${sessions.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: $totalMinutes minutes',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...sessions.map((session) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Builder(
            builder: (context) => _buildSessionCard(context, session),
          ),
        )),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, FocusSession session) {
    final hour = session.startedAt.hour > 12 ? session.startedAt.hour - 12 : session.startedAt.hour;
    final period = session.startedAt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '${hour == 0 ? 12 : hour}:${session.startedAt.minute.toString().padLeft(2, '0')} $period';

    return Container(
      padding: const EdgeInsets.all(16),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: session.status == 'completed'
                      ? LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600])
                      : LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.status == 'completed' ? 'Completed' : 'Ended Early',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${session.durationMinutes} minutes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (session.rating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < session.rating! ? Icons.star : Icons.star_border,
                    size: 20,
                    color: Colors.amber,
                  );
                }),
              ],
            ),
          ],
          if (session.note != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/note-viewer', extra: {
                'note': session.note!,
                'sessionId': session.id,
                'focusDateId': dateId,
              }),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_full_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }
}
