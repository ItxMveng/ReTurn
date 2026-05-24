import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifMatch = true;
  bool _notifMessage = true;
  bool _notifRestitution = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader(label: 'Notifications'),
          _SwitchTile(
            icon: Icons.compare_arrows,
            label: 'Nouvelles correspondances',
            value: _notifMatch,
            onChanged: (v) => setState(() => _notifMatch = v),
          ),
          _SwitchTile(
            icon: Icons.chat_bubble_outline,
            label: 'Nouveaux messages',
            value: _notifMessage,
            onChanged: (v) => setState(() => _notifMessage = v),
          ),
          _SwitchTile(
            icon: Icons.check_circle_outline,
            label: 'Restitutions validées',
            value: _notifRestitution,
            onChanged: (v) => setState(() => _notifRestitution = v),
          ),
          const SizedBox(height: 8),
          _SectionHeader(label: 'Apparence'),
          _SwitchTile(
            icon: Icons.dark_mode_outlined,
            label: 'Mode sombre',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const SizedBox(height: 8),
          _SectionHeader(label: 'Compte'),
          _ActionTile(
            icon: Icons.lock_outline,
            label: 'Changer le mot de passe',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.phone_outlined,
            label: 'Modifier le numéro',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _SectionHeader(label: 'À propos'),
          _ActionTile(
            icon: Icons.info_outline,
            label: 'Version 1.0.0',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.description_outlined,
            label: 'Conditions d\'utilisation',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Politique de confidentialité',
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface)),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
