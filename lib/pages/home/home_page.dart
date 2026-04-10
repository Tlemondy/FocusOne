import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../components/fade_in_animation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/session_provider.dart';
import 'components/set_focus_modal.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.value?.displayName ?? 'there';
    final dailyFocusAsync = ref.watch(dailyFocusProvider);
    final insightsAsync = ref.watch(insightsProvider);
    final activeSession = ref.watch(activeSessionProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isWebDesktop = kIsWeb && isDesktop;

    if (isWebDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: FadeInAnimation(
              child: _buildWebHome(
                context,
                ref,
                userName,
                dailyFocusAsync,
                insightsAsync,
                activeSession,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeInAnimation(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(userName, ref, context),
                        const SizedBox(height: 20),
                        _buildTodaysFocus(context, ref, dailyFocusAsync),
                        const SizedBox(height: 16),
                        _buildStreakCard(ref),
                        const Spacer(),
                        const SizedBox(height: 100),
                      ],
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

  Widget _buildHeader(String userName, WidgetRef ref, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Hello, $userName',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: Icon(
                Icons.settings_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'What\'s your focus today?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebHome(
    BuildContext context,
    WidgetRef ref,
    String userName,
    AsyncValue<DailyFocus?> focusAsync,
    AsyncValue<InsightsData> insightsAsync,
    ActiveSessionState? activeSession,
  ) {
    final focus = focusAsync.value;
    final localizations = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final formattedDate = localizations.formatFullDate(now);
    final hasFocus = focus != null;

    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -40,
          child: _buildAmbientGlow(
            size: 320,
            colors: [
              AppColors.primary.withValues(alpha: 0.20),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          left: -80,
          bottom: -140,
          child: _buildAmbientGlow(
            size: 360,
            colors: [
              AppColors.accentOrange.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWebHeader(
                    context,
                    userName,
                    formattedDate,
                    hasFocus,
                    activeSession,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildWebFocusPanel(
                          context,
                          ref,
                          focus,
                          activeSession,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: _buildWebSummaryPanel(
                          context,
                          insightsAsync,
                          activeSession,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildWebPerformanceStrip(context, focus, insightsAsync),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebHeader(
    BuildContext context,
    String userName,
    String formattedDate,
    bool hasFocus,
    ActiveSessionState? activeSession,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.72),
                    ),
                  ),
                  _buildHeaderBadge(
                    icon: hasFocus
                        ? Icons.check_circle_outline_rounded
                        : Icons.radio_button_unchecked_rounded,
                    label: hasFocus ? 'Focus set' : 'Focus empty',
                  ),
                  if (activeSession != null)
                    _buildHeaderBadge(
                      icon: Icons.play_circle_fill_rounded,
                      label:
                          '${_formatMinutes(activeSession.remainingSeconds ~/ 60)} left',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Hello, $userName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'One clear target for today.',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.4,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 620,
                child: Text(
                  hasFocus
                      ? 'Keep the home screen centered on the one outcome that matters, then move straight into execution.'
                      : 'Set a single clear priority and turn it into focused work without extra noise.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textSecondary.withValues(alpha: 0.82),
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
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Icons.settings_rounded,
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

  Widget _buildWebFocusPanel(
    BuildContext context,
    WidgetRef ref,
    DailyFocus? focus,
    ActiveSessionState? activeSession,
  ) {
    final hasFocus = focus != null;
    final bool hasActiveSession = activeSession != null;

    return GlassContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(36),
      opacity: 0.09,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFocus ? 'Current Focus' : 'No Focus Yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasFocus
                          ? focus.title
                          : 'Define the single outcome that deserves your attention.',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.08,
                        letterSpacing: -1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFocus)
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context, ref),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          if (hasActiveSession) ...[
            _buildSessionBanner(activeSession),
            const SizedBox(height: 20),
          ],
          if (hasFocus &&
              focus.reason != null &&
              focus.reason!.trim().isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                focus.reason!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildWebTag(
                icon: Icons.today_rounded,
                label: hasFocus ? 'Set for today' : 'Ready when you are',
              ),
              _buildWebTag(
                icon: hasActiveSession
                    ? Icons.play_circle_fill_rounded
                    : Icons.timelapse_rounded,
                label: hasActiveSession
                    ? 'Session in progress'
                    : 'No active session',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildPrimaryAction(
                  label: hasActiveSession
                      ? 'Resume Session'
                      : hasFocus
                      ? 'Start Focus Session'
                      : 'Set Today\'s Focus',
                  onPressed: () {
                    if (hasFocus) {
                      _navigateToSession(context, focus);
                    } else {
                      _showSetFocusModal(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryAction(
                  label: hasFocus ? 'Reset Focus' : 'Open Focus Setup',
                  onPressed: () {
                    if (hasFocus) {
                      _showDeleteConfirmation(context, ref);
                    } else {
                      _showSetFocusModal(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebSummaryPanel(
    BuildContext context,
    AsyncValue<InsightsData> insightsAsync,
    ActiveSessionState? activeSession,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: BorderRadius.circular(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (activeSession != null)
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeSession != null
                ? 'You already have work in motion. The rest of the page stays secondary.'
                : 'A compact view of consistency, volume, and session quality.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.78),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          insightsAsync.when(
            data: (insights) => Column(
              children: [
                _buildPrimaryMetric(
                  label: 'Current Streak',
                  value: '${insights.focusStreak}',
                  detail: insights.focusStreak == 1
                      ? 'day of consistent focus'
                      : 'days of consistent focus',
                  icon: Icons.local_fire_department_rounded,
                  gradientColors: [Colors.orange.shade400, Colors.red.shade500],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        label: 'This Week',
                        value: '${insights.totalMinutesThisWeek}',
                        detail: 'minutes',
                        icon: Icons.schedule_rounded,
                        gradientColors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        label: 'Sessions',
                        value: '${insights.totalSessions}',
                        detail: 'logged',
                        icon: Icons.stacked_bar_chart_rounded,
                        gradientColors: [
                          const Color(0xFF00B8A9),
                          const Color(0xFF00A1FF),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCompactStatRow(
                  leftLabel: 'Completed Focuses',
                  leftValue: '${insights.completedFocuses}',
                  rightLabel: 'Average Rating',
                  rightValue: insights.averageRating == 0
                      ? '0.0'
                      : insights.averageRating.toStringAsFixed(1),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) =>
                _buildAsyncFallback('Unable to load your overview right now.'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPerformanceStrip(
    BuildContext context,
    DailyFocus? focus,
    AsyncValue<InsightsData> insightsAsync,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: BorderRadius.circular(36),
      opacity: 0.08,
      child: insightsAsync.when(
        data: (insights) {
          final cards = [
            (
              'Focuses Finished',
              '${insights.completedFocuses}',
              focus == null ? 'No active focus now' : 'Current focus is active',
            ),
            (
              'Weekly Volume',
              '${insights.totalMinutesThisWeek}',
              insights.totalMinutesThisWeek == 1
                  ? 'minute logged this week'
                  : 'minutes logged this week',
            ),
            (
              'Session Count',
              '${insights.totalSessions}',
              insights.totalSessions == 1
                  ? 'session recorded'
                  : 'sessions recorded',
            ),
          ];

          return Row(
            children: [
              for (int index = 0; index < cards.length; index++) ...[
                Expanded(
                  child: _buildPerformanceCard(
                    title: cards[index].$1,
                    value: cards[index].$2,
                    subtitle: cards[index].$3,
                  ),
                ),
                if (index < cards.length - 1)
                  Container(
                    width: 1,
                    height: 96,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
              ],
            ],
          );
        },
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) =>
            _buildAsyncFallback('Performance data is unavailable right now.'),
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

  Widget _buildWebTag({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.94),
            ),
          ),
        ],
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

  Widget _buildSessionBanner(ActiveSessionState session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.secondary.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session in progress',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatMinutes(session.remainingSeconds ~/ 60)} remaining from ${session.selectedDurationMinutes}m',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
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
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.8,
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

  Widget _buildPrimaryMetric({
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors.first.withValues(alpha: 0.18),
            gradientColors.last.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInlineStat(label: leftLabel, value: leftValue),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: _buildInlineStat(label: rightLabel, value: rightValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.74),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsyncFallback(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '${remainingMinutes}m';
    }

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  Widget _buildTodaysFocus(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DailyFocus?> focusAsync,
  ) {
    final focus = focusAsync.value;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Today\'s Focus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (focus == null)
            ..._buildEmptyState(context)
          else
            ..._buildFocusContent(context, ref, focus),
        ],
      ),
    );
  }

  List<Widget> _buildEmptyState(BuildContext context) {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No focus set yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap below to set your one priority for today',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => _showSetFocusModal(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
          child: const Text(
            'Set Today\'s Focus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFocusContent(
    BuildContext context,
    WidgetRef ref,
    DailyFocus focus,
  ) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.secondary.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    focus.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(context, ref),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (focus.reason != null) ...[
              const SizedBox(height: 12),
              Text(
                focus.reason!,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => _navigateToSession(context, focus),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Start Focus Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  void _navigateToSession(BuildContext context, DailyFocus focus) {
    context.push(
      '/focus-session',
      extra: {'title': focus.title, 'reason': focus.reason, 'dateId': focus.id},
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Focus?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete today\'s focus?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(dailyFocusProvider.notifier).deleteFocus();
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetFocusModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SetFocusModal(),
    );
  }

  Widget _buildStreakCard(WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      data: (insights) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade400.withValues(alpha: 0.2),
              Colors.red.shade600.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus Streak',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${insights.focusStreak}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          insights.focusStreak == 1 ? 'day' : 'days',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
