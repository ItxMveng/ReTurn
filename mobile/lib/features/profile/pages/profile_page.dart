import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/profile_repository.dart';
import '../models/user_profile.dart';
import '../../auth/repositories/auth_repository.dart';

final _profileProvider =
    FutureProvider<UserProfile>(
        (ref) => ref.read(profileRepositoryProvider).me());

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_profileProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings')),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: cs.primary.withOpacity(0.12),
                child: Text(
                    p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: cs.primary)),
              ),
              const SizedBox(height: 16),
              Text(p.fullName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(p.phone,
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.5))),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StatCard('Déclarations', '${p.declarationsCount}', cs.primary),
                const SizedBox(width: 12),
                _StatCard('Restitutions', '${p.restitutionsCount}',
                    Colors.green),
                const SizedBox(width: 12),
                _StatCard('Réputation', '${p.reputationPercent}%',
                    Colors.orange),
              ]),
              const SizedBox(height: 28),
              Column(
                children: [
                  const Text('Score de réputation',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: p.reputation,
                    backgroundColor:
                        cs.primary.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
