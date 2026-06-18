import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../declarations/providers/declaration_provider.dart';
import '../../matching/providers/match_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final declarationsState = ref.watch(declarationListProvider);
    final matchesState = ref.watch(matchListProvider);

    final decCount = declarationsState.valueOrNull?.length ?? 0;
    final pendingCount = matchesState.valueOrNull
            ?.where((m) => m.status == 'pending')
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocRetour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.description_outlined,
                    label: 'Déclarations',
                    value: decCount.toString(),
                    color: Colors.blue,
                    onTap: () => context.push('/declarations'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.compare_arrows,
                    label: 'Matchs',
                    value: pendingCount.toString(),
                    color: Colors.orange,
                    onTap: () => context.push('/matches'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
