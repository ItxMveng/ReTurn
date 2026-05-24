import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/domain/auth_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: auth.when(
        initial: () => const AppLoader(),
        loading: () => const AppLoader(message: 'Chargement du profil…'),
        authenticated: (userId, phone) => _ProfileContent(
          userId: userId,
          phone: phone,
          onLogout: () => ref.read(authProvider.notifier).logout().then(
                (_) => context.go('/login'),
              ),
        ),
        unauthenticated: () {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return const SizedBox.shrink();
        },
        error: (msg) => Center(
          child: Text(msg,
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String userId;
  final String phone;
  final VoidCallback onLogout;

  const _ProfileContent({
    required this.userId,
    required this.phone,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.person, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            phone,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: $userId',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Statistiques
          _StatsRow(),

          const SizedBox(height: 32),

          // Menu
          _MenuCard(
            items: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: 'Mes déclarations',
                onTap: () => context.go('/declarations'),
              ),
              _MenuItem(
                icon: Icons.compare_arrows_outlined,
                label: 'Mes correspondances',
                onTap: () => context.go('/matches'),
              ),
              _MenuItem(
                icon: Icons.chat_bubble_outline,
                label: 'Mes messages',
                onTap: () => context.go('/messages'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _MenuCard(
            items: [
              _MenuItem(
                icon: Icons.help_outline,
                label: 'Aide & Support',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Confidentialité',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),

          AppButton(
            label: 'Se déconnecter',
            variant: AppButtonVariant.danger,
            expand: true,
            icon: const Icon(Icons.logout, size: 18, color: Colors.white),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                value: '—', label: 'Déclarations', icon: Icons.article_outlined)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                value: '—', label: 'Matchs', icon: Icons.compare_arrows)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                value: '—', label: 'Restitutions', icon: Icons.check_circle_outline)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.onSurface)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...
            [
              items[i],
              if (i < items.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
