import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:return_mobile/features/restitution/providers/restitution_provider.dart';
import 'package:return_mobile/shared/models/restitution.dart';

class RestitutionsListScreen extends ConsumerWidget {
  const RestitutionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(restitutionListProvider);
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restitutions'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'En cours'),
              Tab(text: 'Terminées'),
            ],
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
            indicatorColor: cs.primary,
          ),
        ),
        body: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(restitutionListProvider),
          ),
          data: (list) => TabBarView(
            children: [
              _RestitutionTab(
                items: list.where((r) => r.isActive).toList(),
                emptyLabel: 'Aucune restitution en cours',
                onRefresh: () =>
                    ref.read(restitutionListProvider.notifier).refresh(),
              ),
              _RestitutionTab(
                items: list.where((r) => !r.isActive).toList(),
                emptyLabel: 'Aucune restitution terminée',
                onRefresh: () =>
                    ref.read(restitutionListProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class _RestitutionTab extends StatelessWidget {
  const _RestitutionTab({
    required this.items,
    required this.emptyLabel,
    required this.onRefresh,
  });
  final List<Restitution> items;
  final String emptyLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      // L'empty state est aussi scroll-able pour que pull-to-refresh fonctionne
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 64,
                        color: cs.onSurface.withValues(alpha: 0.18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tirez vers le bas pour actualiser',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AnimatedCard(
          index: i,
          child: _RestitutionCard(restitution: items[i]),
        ),
      ),
    );
  }
}

// ── Animated card wrapper (staggered entrance) ────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger: chaque carte apparaît 50ms après la précédente
    Future.delayed(
      Duration(milliseconds: widget.index * 50),
      () { if (mounted) _ctrl.forward(); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _RestitutionCard extends StatelessWidget {
  const _RestitutionCard({required this.restitution});
  final Restitution restitution;

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      'requested' => cs.primary,
      'verified'  => Colors.orange,
      'completed' => Colors.green,
      'disputed'  => cs.error,
      'cancelled' => cs.onSurface.withValues(alpha: 0.4),
      _           => cs.outline,
    };
  }

  IconData _statusIcon(String status) => switch (status) {
        'requested' => Icons.pending_outlined,
        'verified'  => Icons.verified_user_outlined,
        'completed' => Icons.check_circle_outline,
        'disputed'  => Icons.report_problem_outlined,
        'cancelled' => Icons.cancel_outlined,
        _           => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(context, restitution.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/restitutions/${restitution.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(restitution.status),
                    color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restitution #${restitution.id.substring(0, 8)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            restitution.statusLabel,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (restitution.meetingLocation != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              restitution.meetingLocation!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text('Erreur de chargement',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Recharger'),
            ),
          ],
        ),
      ),
    );
  }
}
