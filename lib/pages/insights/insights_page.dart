import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/insights_provider.dart';
import '../../widgets/page_header.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isWebDesktop = kIsWeb && isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: insightsAsync.when(
          data: (insights) => isWebDesktop
              ? _buildWebInsights(context, insights)
              : _buildInsights(context, insights, isDesktop),
          loading: () => Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const PageHeader(title: 'Insights', showBackButton: false),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (e, _) => Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const PageHeader(title: 'Insights', showBackButton: false),
              Expanded(child: Center(child: Text('Error: $e'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebInsights(BuildContext context, InsightsData insights) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -40,
          child: _buildAmbientGlow(
            size: 320,
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ),
        ),
        Positioned(
          left: -90,
          bottom: -120,
          child: _buildAmbientGlow(
            size: 360,
            colors: [
              AppColors.secondary.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWebHeader(context, insights),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPrimaryMetricGrid(insights),
                              const SizedBox(height: 18),
                              _buildSupportingMetrics(insights),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 4,
                          child: _buildInsightSidebar(insights),
                        ),
                      ],
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

  Widget _buildWebHeader(BuildContext context, InsightsData insights) {
    final strongestSignal = insights.focusStreak >= 1
        ? '${insights.focusStreak}-day streak'
        : insights.totalMinutesThisWeek > 0
        ? '${insights.totalMinutesThisWeek} minutes this week'
        : 'No activity yet';

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
                children: [
                  _buildHeaderBadge(
                    icon: Icons.auto_graph_rounded,
                    label: strongestSignal,
                  ),
                  _buildHeaderBadge(
                    icon: Icons.insights_rounded,
                    label: 'All core metrics in one view',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.1,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 720,
                child: Text(
                  'A simple view of consistency, volume, and quality. Nothing extra, just the numbers that matter.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
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

  Widget _buildPrimaryMetricGrid(InsightsData insights) {
    final cards = [
      _InsightMetric(
        label: 'Focus Streak',
        value: '${insights.focusStreak}',
        detail: insights.focusStreak == 1 ? 'day' : 'days',
        icon: Icons.local_fire_department_rounded,
        accent: Colors.white,
      ),
      _InsightMetric(
        label: 'This Week',
        value: '${insights.totalMinutesThisWeek}',
        detail: 'minutes',
        icon: Icons.timer_outlined,
        accent: Colors.white,
      ),
      _InsightMetric(
        label: 'Average Rating',
        value: insights.averageRating > 0
            ? insights.averageRating.toStringAsFixed(1)
            : '—',
        detail: insights.averageRating > 0 ? 'out of 5' : 'no ratings',
        icon: Icons.star_rounded,
        accent: Colors.white,
      ),
      _InsightMetric(
        label: 'Completed Focuses',
        value: '${insights.completedFocuses}',
        detail: 'all time',
        icon: Icons.check_circle_outline_rounded,
        accent: Colors.white,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 700;
        if (!useTwoColumns) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                _buildModernMetricCard(cards[i], featured: i < 2),
                if (i < cards.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildModernMetricCard(cards[0], featured: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildModernMetricCard(cards[1], featured: true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildModernMetricCard(cards[2])),
                const SizedBox(width: 14),
                Expanded(child: _buildModernMetricCard(cards[3])),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupportingMetrics(InsightsData insights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Volume',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${insights.totalSessions}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insights.totalSessions == 1
                            ? 'session recorded overall'
                            : 'sessions recorded overall',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.78,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSidebar(InsightsData insights) {
    final consistency = insights.focusStreak >= 5
        ? 'Strong consistency'
        : insights.focusStreak >= 1
        ? 'Consistency building'
        : 'No streak yet';

    final quality = insights.averageRating >= 4
        ? 'High quality sessions'
        : insights.averageRating > 0
        ? 'Session quality is mixed'
        : 'No quality signal yet';

    return Column(
      children: [
        Container(
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
              const Text(
                'Readout',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildSimpleReadout(label: 'Consistency', value: consistency),
              const SizedBox(height: 14),
              _buildSimpleReadout(label: 'Quality', value: quality),
              const SizedBox(height: 14),
              _buildSimpleReadout(
                label: 'Output',
                value: insights.completedFocuses == 0
                    ? 'No completed focuses yet'
                    : '${insights.completedFocuses} completed, ${insights.totalSessions} sessions logged',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
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
              const Text(
                'Coverage',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildMiniSummaryTile(
                title: 'Weekly Minutes',
                value: '${insights.totalMinutesThisWeek}',
              ),
              const SizedBox(height: 12),
              _buildMiniSummaryTile(
                title: 'Total Sessions',
                value: '${insights.totalSessions}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernMetricCard(
    _InsightMetric metric, {
    bool featured = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(featured ? 22 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: featured ? 0.05 : 0.04),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: featured ? 46 : 42,
            height: featured ? 46 : 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              metric.icon,
              color: metric.accent.withValues(alpha: 0.92),
              size: featured ? 24 : 22,
            ),
          ),
          SizedBox(height: featured ? 18 : 16),
          Text(
            metric.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: featured ? 36 : 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  metric.detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleReadout({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSummaryTile({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.76),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(
    BuildContext context,
    InsightsData insights,
    bool isDesktop,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 900 : double.infinity,
        ),
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
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  child: const PageHeader(
                    title: 'Insights',
                    showBackButton: false,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (isDesktop)
                    ..._buildDesktopLayout(insights)
                  else
                    ..._buildMobileLayout(insights),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    (isDesktop ? 40 : 100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDesktopLayout(InsightsData insights) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department_rounded,
              title: 'Focus Streak',
              value: '${insights.focusStreak}',
              subtitle: insights.focusStreak == 1 ? 'day' : 'days',
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.red.shade600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer_outlined,
              title: 'This Week',
              value: '${insights.totalMinutesThisWeek}',
              subtitle: 'minutes',
              gradient: AppColors.primaryGradient,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.star_rounded,
              title: 'Average Rating',
              value: insights.averageRating > 0
                  ? insights.averageRating.toStringAsFixed(1)
                  : '—',
              subtitle: insights.averageRating > 0
                  ? 'out of 5'
                  : 'no ratings yet',
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Container()),
        ],
      ),
      const SizedBox(height: 32),
      const Text(
        'All Time',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildSmallStatCard(
              icon: Icons.check_circle_outline_rounded,
              title: 'Completed',
              value: '${insights.completedFocuses}',
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSmallStatCard(
              icon: Icons.play_circle_outline_rounded,
              title: 'Sessions',
              value: '${insights.totalSessions}',
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildMobileLayout(InsightsData insights) {
    return [
      _buildStatCard(
        icon: Icons.local_fire_department_rounded,
        title: 'Focus Streak',
        value: '${insights.focusStreak}',
        subtitle: insights.focusStreak == 1 ? 'day' : 'days',
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade600],
        ),
      ),
      const SizedBox(height: 16),
      _buildStatCard(
        icon: Icons.timer_outlined,
        title: 'This Week',
        value: '${insights.totalMinutesThisWeek}',
        subtitle: 'minutes',
        gradient: AppColors.primaryGradient,
      ),
      const SizedBox(height: 16),
      _buildStatCard(
        icon: Icons.star_rounded,
        title: 'Average Rating',
        value: insights.averageRating > 0
            ? insights.averageRating.toStringAsFixed(1)
            : '—',
        subtitle: insights.averageRating > 0 ? 'out of 5' : 'no ratings yet',
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade600],
        ),
      ),
      const SizedBox(height: 32),
      const Text(
        'All Time',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildSmallStatCard(
              icon: Icons.check_circle_outline_rounded,
              title: 'Completed',
              value: '${insights.completedFocuses}',
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSmallStatCard(
              icon: Icons.play_circle_outline_rounded,
              title: 'Sessions',
              value: '${insights.totalSessions}',
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
              ),
            ),
          ),
        ],
      ),
    ];
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                      value,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        subtitle,
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
    );
  }

  Widget _buildSmallStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
  }) {
    return Container(
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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
}

class _InsightMetric {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;

  const _InsightMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
  });
}
