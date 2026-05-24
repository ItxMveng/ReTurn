import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/repositories/auth_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          const _SectionHeader('Compte'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications push'),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.compare_arrows),
            title: const Text('Alertes de matchs'),
            value: true,
            onChanged: (v) {},
          ),
          const Divider(),
          const _SectionHeader('Application'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Langue'),
            trailing: const Text('Français',
                style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Text('v1.0.0',
                style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Se déconnecter',
                style: TextStyle(color: cs.error)),
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.45))),
    );
  }
}
