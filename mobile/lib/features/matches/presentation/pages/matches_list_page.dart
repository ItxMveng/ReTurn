import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/matches_notifier.dart';
import '../../data/models/match_model.dart';
import '../widgets/match_card.dart';

class MatchesListPage extends ConsumerStatefulWidget {
  const MatchesListPage({super.key});

  @override
  ConsumerState<MatchesListPage> createState() => _MatchesListPageState();
}

class _MatchesListPageState extends ConsumerState<MatchesListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Correspondances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(matchesNotifierProvider.notifier).fetch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'En attente (${state.pending.length})'),
            Tab(text: 'Confirmés (${state.confirmed.length})'),
            Tab(text: 'Terminés (${state.completed.length})'),
          ],
        ),
      ),
      body: state.isLoading
          ? _buildSkeletons()
          : TabBarView(
              controller: _tabs,
              children: [
                _MatchTab(matches: state.pending,   emptyText: 'Aucune correspondance en attente'),
                _MatchTab(matches: state.confirmed, emptyText: 'Aucune correspondance confirmée'),
                _MatchTab(matches: state.completed, emptyText: 'Aucune restitution terminée'),
              ],
            ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _MatchTab extends ConsumerWidget {
  const _MatchTab({required this.matches, required this.emptyText});
  final List<MatchModel> matches;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded, size: 56, color: AppColors.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(emptyText, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(matchesNotifierProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => MatchCard(
          match: matches[i],
          onTap: () => context.pushNamed('match-detail', pathParameters: {'id': matches[i].id}),
        ),
      ),
    );
  }
}
