import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/case_model.dart';
import '../../../providers/citizen_cases_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/demo_data_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  My Cases Screen — Citizen case dashboard
// ─────────────────────────────────────────────────────────────────────────────

class MyCasesScreen extends ConsumerStatefulWidget {
  const MyCasesScreen({super.key});

  @override
  ConsumerState<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends ConsumerState<MyCasesScreen> {
  String _searchQuery = '';
  CaseStatus? _filterStatus;

  List<CaseModel> _filtered(List<CaseModel> all) {
    var list = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.id.toLowerCase().contains(q) ||
              c.title.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q))
          .toList();
    }
    if (_filterStatus != null) {
      list = list.where((c) => c.status == _filterStatus).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(citizenCasesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search cases',
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: _CaseSearchDelegate(ref),
              );
              if (result != null && mounted) {
                context.push('/cases/$result');
              }
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: DemoDataBanner(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.reportCase),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report Case',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: casesAsync.when(
        loading: () => const _LoadingState(),
        error: (err, _) => _ErrorState(
          onRetry: () => ref.refresh(citizenCasesProvider),
        ),
        data: (cases) {
          final filtered = _filtered(cases);
          return Column(
            children: [
              // ── Search + Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by Case ID, title, or location…',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textMuted),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _filterStatus == null,
                            onTap: () =>
                                setState(() => _filterStatus = null),
                          ),
                          const SizedBox(width: 8),
                          ...CaseStatus.values.map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: s.label,
                                  isSelected: _filterStatus == s,
                                  onTap: () =>
                                      setState(() => _filterStatus = s),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stats bar
              if (cases.isNotEmpty)
                _StatsBar(cases: cases),

              // ── Case list
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        isFiltered:
                            _searchQuery.isNotEmpty || _filterStatus != null,
                        onReport: () => context.push(AppRoutes.reportCase),
                        onClearFilter: () => setState(() {
                          _searchQuery = '';
                          _filterStatus = null;
                        }),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () =>
                            ref.refresh(citizenCasesProvider.future),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _CaseCard(caseModel: filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Stats bar
class _StatsBar extends StatelessWidget {
  final List<CaseModel> cases;
  const _StatsBar({required this.cases});

  @override
  Widget build(BuildContext context) {
    final investigating =
        cases.where((c) => c.status == CaseStatus.investigating).length;
    final resolved =
        cases.where((c) => c.status == CaseStatus.resolved).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(label: 'Total', value: '${cases.length}',
              color: AppColors.textPrimary),
          _Divider(),
          _StatItem(
              label: 'Active',
              value: '$investigating',
              color: AppColors.statusInvestigating),
          _Divider(),
          _StatItem(
              label: 'Resolved',
              value: '$resolved',
              color: AppColors.statusResolved),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }
}

// ── Case card
class _CaseCard extends StatelessWidget {
  final CaseModel caseModel;
  const _CaseCard({required this.caseModel});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = caseModel;
    return GestureDetector(
      onTap: () => context.push('/cases/${c.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.id,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                StatusBadge(status: c.status),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              c.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Category
            Text(
              c.categoryLabel,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Footer row
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    c.location,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatDate(c.submittedAt),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textMuted),
              ],
            ),

            // Anonymous badge
            if (c.isAnonymous) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off_outlined,
                        size: 12, color: AppColors.textMuted),
                    SizedBox(width: 5),
                    Text('Anonymous report',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Loading state
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const _ShimmerBox(),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Error state
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Could not load cases',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state
class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onReport;
  final VoidCallback onClearFilter;
  const _EmptyState({
    required this.isFiltered,
    required this.onReport,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.folder_open_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No matching cases' : 'No cases yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try a different search or clear filters.'
                  : 'Report an incident to start tracking your case.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (isFiltered)
              OutlinedButton(
                onPressed: onClearFilter,
                child: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Report an Incident'),
              ),
          ],
        ),
      ),
    );
  }
}

// ── In-app search delegate
class _CaseSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  _CaseSearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => close(context, ''),
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSuggestions();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSuggestions();

  Widget _buildSuggestions() {
    return Consumer(
      builder: (context, ref, _) {
        final casesAsync = ref.watch(citizenCasesProvider);
        return casesAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (_, __) => const SizedBox(),
          data: (cases) {
            final q = query.toLowerCase();
            final results = cases
                .where((c) =>
                    c.id.toLowerCase().contains(q) ||
                    c.title.toLowerCase().contains(q))
                .toList();

            if (results.isEmpty) {
              return Center(
                child: Text('No results for "$query"',
                    style: const TextStyle(color: AppColors.textMuted)),
              );
            }

            return ListView(
              children: results
                  .map((c) => ListTile(
                        tileColor: AppColors.surface,
                        leading: const Icon(Icons.folder_outlined,
                            color: AppColors.accent),
                        title: Text(c.id,
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(c.title,
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        onTap: () => close(context, c.id),
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }
}
