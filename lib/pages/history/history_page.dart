import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_one/providers/focus_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/page_header.dart';

final completedFocusesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];

  final service = ref.read(firestoreServiceProvider);
  return await service.getCompletedFocuses(authState.uid);
});

enum _HistorySortOption { newest, oldest, title }

enum _HistoryFilter { all, withNotes, thisMonth, thisYear }

enum _HistoryViewMode { cards, list }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  static const int _pageSize = 12;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _HistorySortOption _sortOption = _HistorySortOption.newest;
  _HistoryFilter _filter = _HistoryFilter.all;
  _HistoryViewMode _viewMode = _HistoryViewMode.cards;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusesAsync = ref.watch(completedFocusesProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isWebDesktop = kIsWeb && isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: focusesAsync.when(
          data: (focuses) {
            if (focuses.isEmpty) {
              return isWebDesktop
                  ? _buildWebEmptyState()
                  : Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        const PageHeader(
                          title: 'History',
                          showBackButton: false,
                        ),
                        Expanded(child: _buildEmptyState()),
                      ],
                    );
            }

            return isWebDesktop
                ? _buildWebHistory(context, focuses)
                : _buildHistoryList(context, focuses, isDesktop);
          },
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

  Widget _buildWebHistory(
    BuildContext context,
    List<Map<String, dynamic>> focuses,
  ) {
    final filteredFocuses = _applyFilters(focuses);
    final totalPages = filteredFocuses.isEmpty
        ? 1
        : (filteredFocuses.length / _pageSize).ceil();
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final pagedFocuses = filteredFocuses
        .skip(safePage * _pageSize)
        .take(_pageSize)
        .toList();
    final latestDate = focuses.map(_focusDate).reduce(_latestDate);
    final earliestDate = focuses.map(_focusDate).reduce(_earliestDate);
    final withNotesCount = focuses.where(_hasReason).length;

    return SafeArea(
      child: Stack(
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
            left: -100,
            bottom: -120,
            child: _buildAmbientGlow(
              size: 360,
              colors: [
                AppColors.secondary.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWebHero(
                      context,
                      focuses.length,
                      filteredFocuses.length,
                      latestDate,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWebControls(
                                visibleCount: filteredFocuses.length,
                                currentPage: safePage,
                                totalPages: totalPages,
                              ),
                              const SizedBox(height: 18),
                              _buildWebFocusContent(
                                context,
                                filteredFocuses: filteredFocuses,
                                pagedFocuses: pagedFocuses,
                                currentPage: safePage,
                                totalPages: totalPages,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 3,
                          child: _buildWebSideRail(
                            totalCount: focuses.length,
                            visibleCount: filteredFocuses.length,
                            currentPage: safePage,
                            totalPages: totalPages,
                            earliestDate: earliestDate,
                            latestDate: latestDate,
                            withNotesCount: withNotesCount,
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
      ),
    );
  }

  Widget _buildWebHero(
    BuildContext context,
    int totalCount,
    int filteredCount,
    DateTime latestDate,
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
                children: [
                  _buildHeaderBadge(
                    icon: Icons.history_toggle_off_rounded,
                    label: '$totalCount completed',
                  ),
                  _buildHeaderBadge(
                    icon: Icons.search_rounded,
                    label: '$filteredCount visible',
                  ),
                  _buildHeaderBadge(
                    icon: Icons.event_available_rounded,
                    label: 'Latest ${_formatShortDate(latestDate)}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'Find the exact focus fast.',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1.4,
                    height: 1.04,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 720,
                child: Text(
                  'This web view is optimized for search and quick scanning. Narrow the list, page through results, and open the detail you need without a noisy wall of cards.',
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

  Widget _buildWebControls({
    required int visibleCount,
    required int currentPage,
    required int totalPages,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: BorderRadius.circular(34),
      opacity: 0.09,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search History',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Search is the primary action here. Filters and pagination are secondary controls for reducing the result set.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildWebActionButton(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                onPressed: _refreshHistory,
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
                _currentPage = 0;
              });
            },
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search by title or note',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.58),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 52),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 0;
                        });
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '$visibleCount results',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Page ${currentPage + 1} of $totalPages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              _buildCompactPagination(
                currentPage: currentPage,
                totalPages: totalPages,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      selected: _filter == _HistoryFilter.all,
                      onTap: () => _setFilter(_HistoryFilter.all),
                    ),
                    _buildFilterChip(
                      label: 'With Notes',
                      selected: _filter == _HistoryFilter.withNotes,
                      onTap: () => _setFilter(_HistoryFilter.withNotes),
                    ),
                    _buildFilterChip(
                      label: 'This Month',
                      selected: _filter == _HistoryFilter.thisMonth,
                      onTap: () => _setFilter(_HistoryFilter.thisMonth),
                    ),
                    _buildFilterChip(
                      label: 'This Year',
                      selected: _filter == _HistoryFilter.thisYear,
                      onTap: () => _setFilter(_HistoryFilter.thisYear),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildDropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_HistorySortOption>(
                    value: _sortOption,
                    dropdownColor: const Color(0xFF17203A),
                    borderRadius: BorderRadius.circular(20),
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: AppColors.textSecondary,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _sortOption = value;
                        _currentPage = 0;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: _HistorySortOption.newest,
                        child: Text('Newest first'),
                      ),
                      DropdownMenuItem(
                        value: _HistorySortOption.oldest,
                        child: Text('Oldest first'),
                      ),
                      DropdownMenuItem(
                        value: _HistorySortOption.title,
                        child: Text('Title A-Z'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildViewToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebFocusContent(
    BuildContext context, {
    required List<Map<String, dynamic>> filteredFocuses,
    required List<Map<String, dynamic>> pagedFocuses,
    required int currentPage,
    required int totalPages,
  }) {
    if (filteredFocuses.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(28),
        borderRadius: BorderRadius.circular(32),
        opacity: 0.08,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.search_off_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No results match your current filters.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try clearing search or switching to a broader time range.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildWebActionButton(
              icon: Icons.restart_alt_rounded,
              label: 'Reset',
              onPressed: _resetWebFilters,
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(32),
      opacity: 0.08,
      child: Column(
        children: [
          _viewMode == _HistoryViewMode.cards
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1180
                        ? 3
                        : constraints.maxWidth >= 760
                        ? 2
                        : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 188,
                      ),
                      itemCount: pagedFocuses.length,
                      itemBuilder: (context, index) =>
                          _buildWebFocusCard(context, pagedFocuses[index]),
                    );
                  },
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pagedFocuses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildWebFocusRow(context, pagedFocuses[index]),
                ),
          const SizedBox(height: 18),
          _buildBottomPagination(
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: filteredFocuses.length,
            pageCount: pagedFocuses.length,
          ),
        ],
      ),
    );
  }

  Widget _buildWebSideRail({
    required int totalCount,
    required int visibleCount,
    required int currentPage,
    required int totalPages,
    required DateTime earliestDate,
    required DateTime latestDate,
    required int withNotesCount,
  }) {
    final noteCoverage = totalCount == 0
        ? 0
        : ((withNotesCount / totalCount) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(32),
          opacity: 0.09,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse State',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              _buildRailStat(
                label: 'Visible',
                value: '$visibleCount',
                caption: 'results after search and filters',
              ),
              const SizedBox(height: 14),
              _buildRailStat(
                label: 'Page',
                value: '${currentPage + 1}/$totalPages',
                caption: 'current pagination position',
              ),
              const SizedBox(height: 14),
              _buildRailStat(
                label: 'Notes',
                value: '$noteCoverage%',
                caption: 'of all completed focuses include notes',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(32),
          opacity: 0.09,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Range',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              _buildRailStat(
                label: 'First Completion',
                value: _formatShortDate(earliestDate),
                caption: 'oldest record in your archive',
              ),
              const SizedBox(height: 14),
              _buildRailStat(
                label: 'Latest Completion',
                value: _formatShortDate(latestDate),
                caption: 'most recent completed focus',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<Map<String, dynamic>> focuses,
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
                    title: 'History',
                    showBackButton: false,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24),
              sliver: isDesktop
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.5,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildFocusCard(context, focuses[index]),
                        childCount: focuses.length,
                      ),
                    )
                  : SliverList(
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

  Widget _buildWebEmptyState() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: GlassContainer(
              padding: const EdgeInsets.all(40),
              borderRadius: BorderRadius.circular(36),
              opacity: 0.08,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildHeaderBadge(
                              icon: Icons.history_rounded,
                              label: 'History is empty',
                            ),
                            _buildHeaderBadge(
                              icon: Icons.search_rounded,
                              label: 'Search-first web view',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'Once you complete focuses, this becomes your archive browser.',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1.2,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'You will be able to search, filter, and page through completed work without the screen becoming cluttered.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.84,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildWebActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Refresh',
                          onPressed: _refreshHistory,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
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
                              Icons.history_toggle_off_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Nothing completed yet',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Finish and complete a focus to start building a searchable history here.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildWebFocusCard(BuildContext context, Map<String, dynamic> focus) {
    final title = _focusTitle(focus);
    final reason = _focusReason(focus);
    final date = _focusDate(focus);

    return InkWell(
      onTap: () => _openFocus(context, focus, date),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _formatShortDate(date),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildMiniBadge(
                  icon: _hasReason(focus)
                      ? Icons.notes_rounded
                      : Icons.check_circle_outline_rounded,
                  label: _hasReason(focus) ? 'Note' : 'Clean',
                ),
                const Spacer(),
                _buildDeleteIconButton(
                  onPressed: () => _deleteFocusFromHistory(context, focus),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                reason ?? 'Completed without an added note.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary.withValues(alpha: 0.88),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _monthName(date.month),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                _buildWebActionButton(
                  icon: Icons.arrow_outward_rounded,
                  label: 'View',
                  onPressed: () => _openFocus(context, focus, date),
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFocusRow(BuildContext context, Map<String, dynamic> focus) {
    final title = _focusTitle(focus);
    final reason = _focusReason(focus);
    final date = _focusDate(focus);

    return InkWell(
      onTap: () => _openFocus(context, focus, date),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatShortDate(date),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason ?? 'Completed without an added note.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _buildMiniBadge(
              icon: _hasReason(focus)
                  ? Icons.notes_rounded
                  : Icons.check_circle_outline_rounded,
              label: _hasReason(focus) ? 'Note' : 'Clean',
            ),
            const SizedBox(width: 12),
            _buildDeleteIconButton(
              onPressed: () => _deleteFocusFromHistory(context, focus),
            ),
            const SizedBox(width: 12),
            _buildWebActionButton(
              icon: Icons.arrow_outward_rounded,
              label: 'View',
              onPressed: () => _openFocus(context, focus, date),
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard(BuildContext context, Map<String, dynamic> focus) {
    final date = _focusDate(focus);
    final dateStr = '${_monthName(date.month)} ${date.day}, ${date.year}';

    return GestureDetector(
      onTap: () => _openFocus(context, focus, date),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _focusTitle(focus),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _buildDeleteIconButton(
                  onPressed: () => _deleteFocusFromHistory(context, focus),
                ),
              ],
            ),
            if (_hasReason(focus)) ...[
              const SizedBox(height: 6),
              Text(
                _focusReason(focus)!,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

  Widget _buildMiniBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: selected ? 1 : 0.86),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.dashboard_outlined,
            selected: _viewMode == _HistoryViewMode.cards,
            onTap: () => setState(() => _viewMode = _HistoryViewMode.cards),
          ),
          const SizedBox(width: 6),
          _buildToggleButton(
            icon: Icons.view_agenda_rounded,
            selected: _viewMode == _HistoryViewMode.list,
            onTap: () => setState(() => _viewMode = _HistoryViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _buildWebActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool compact = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 16 : 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 12 : 16,
          ),
          textStyle: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteIconButton({required VoidCallback onPressed}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.28)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
        tooltip: 'Delete focus',
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCompactPagination({
    required int currentPage,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 0,
            onTap: () => setState(() => _currentPage--),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withValues(alpha: 0.84),
              ),
            ),
          ),
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages - 1,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPagination({
    required int currentPage,
    required int totalPages,
    required int totalResults,
    required int pageCount,
  }) {
    final start = totalResults == 0 ? 0 : currentPage * _pageSize + 1;
    final end = totalResults == 0 ? 0 : start + pageCount - 1;

    return Row(
      children: [
        Text(
          'Showing $start-$end of $totalResults',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.76),
          ),
        ),
        const Spacer(),
        _buildCompactPagination(
          currentPage: currentPage,
          totalPages: totalPages,
        ),
      ],
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? Colors.white
              : AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildRailStat({
    required String label,
    required String value,
    required String caption,
  }) {
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

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> focuses) {
    final now = DateTime.now();

    final filtered = focuses.where((focus) {
      final title = _focusTitle(focus).toLowerCase();
      final reason = (_focusReason(focus) ?? '').toLowerCase();
      final date = _focusDate(focus);

      final matchesSearch =
          _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          reason.contains(_searchQuery);
      if (!matchesSearch) return false;

      switch (_filter) {
        case _HistoryFilter.all:
          return true;
        case _HistoryFilter.withNotes:
          return _hasReason(focus);
        case _HistoryFilter.thisMonth:
          return date.year == now.year && date.month == now.month;
        case _HistoryFilter.thisYear:
          return date.year == now.year;
      }
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case _HistorySortOption.newest:
          return _focusDate(b).compareTo(_focusDate(a));
        case _HistorySortOption.oldest:
          return _focusDate(a).compareTo(_focusDate(b));
        case _HistorySortOption.title:
          return _focusTitle(
            a,
          ).toLowerCase().compareTo(_focusTitle(b).toLowerCase());
      }
    });

    return filtered;
  }

  void _setFilter(_HistoryFilter filter) {
    setState(() {
      _filter = filter;
      _currentPage = 0;
    });
  }

  void _resetWebFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filter = _HistoryFilter.all;
      _sortOption = _HistorySortOption.newest;
      _viewMode = _HistoryViewMode.cards;
      _currentPage = 0;
    });
  }

  bool _hasReason(Map<String, dynamic> focus) {
    final reason = _focusReason(focus);
    return reason != null && reason.trim().isNotEmpty;
  }

  String _focusTitle(Map<String, dynamic> focus) {
    return (focus['title'] as String? ?? '').trim();
  }

  String? _focusReason(Map<String, dynamic> focus) {
    final reason = focus['reason'] as String?;
    if (reason == null || reason.trim().isEmpty) return null;
    return reason.trim();
  }

  DateTime _focusDate(Map<String, dynamic> focus) {
    final completedAt = focus['completedAt'];
    if (completedAt != null) {
      return (completedAt as dynamic).toDate() as DateTime;
    }

    return (focus['date'] as dynamic).toDate() as DateTime;
  }

  DateTime _latestDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  DateTime _earliestDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  void _openFocus(
    BuildContext context,
    Map<String, dynamic> focus,
    DateTime date,
  ) {
    context.push(
      '/focus-detail/${focus['id']}',
      extra: {
        'title': _focusTitle(focus),
        'reason': _focusReason(focus),
        'date': date,
      },
    );
  }

  void _refreshHistory() {
    ref.invalidate(completedFocusesProvider);
  }

  Future<void> _deleteFocusFromHistory(
    BuildContext context,
    Map<String, dynamic> focus,
  ) async {
    final shouldDelete = await _showDeleteConfirmation(context, focus);
    if (!shouldDelete || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final authState = await ref.read(authStateProvider.future);
      if (authState == null) return;

      final service = ref.read(firestoreServiceProvider);
      await service.deleteCompletedFocus(authState.uid, focus['id'] as String);

      ref.invalidate(completedFocusesProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('History item deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete history item: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> focus,
  ) async {
    final title = _focusTitle(focus);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11192D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete History Item?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete "$title" and all its saved sessions from your history?',
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

    return result ?? false;
  }

  String _formatShortDate(DateTime date) {
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
}
