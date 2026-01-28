import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_one/providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/page_header.dart';

final completedFocusesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];
  
  final service = ref.read(firestoreServiceProvider);
  return await service.getCompletedFocuses(authState.uid);
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusesAsync = ref.watch(completedFocusesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: focusesAsync.when(
          data: (focuses) => focuses.isEmpty
              ? Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    const PageHeader(title: 'History', showBackButton: false),
                    Expanded(child: _buildEmptyState()),
                  ],
                )
              : _buildHistoryList(context, focuses),
          loading: () => Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const PageHeader(title: 'History', showBackButton: false),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
          error: (e, _) => Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const PageHeader(title: 'History', showBackButton: false),
              Expanded(child: Center(child: Text('Error: $e'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<Map<String, dynamic>> focuses) {
    return CustomScrollView(
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
              child: const PageHeader(title: 'History', showBackButton: false),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFocusCard(context, focuses[index]),
              ),
              childCount: focuses.length,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 100),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No completed focuses yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildFocusCard(BuildContext context, Map<String, dynamic> focus) {
    final date = (focus['date'] as dynamic).toDate() as DateTime;
    final dateStr = '${_monthName(date.month)} ${date.day}, ${date.year}';

    return GestureDetector(
      onTap: () => context.push('/focus-detail/${focus['id']}', extra: {
        'title': focus['title'],
        'reason': focus['reason'],
        'date': date,
      }),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              focus['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (focus['reason'] != null) ...[
              const SizedBox(height: 6),
              Text(
                focus['reason'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}
