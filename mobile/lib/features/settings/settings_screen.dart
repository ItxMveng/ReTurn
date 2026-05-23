import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/providers/settings_provider.dart';
import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
import 'package:docretour/features/profile/providers/profile_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditContactSheet(
      BuildContext context, WidgetRef ref, UserProfile? profile) {
    final phoneCtrl =
        TextEditingController(text: profile?.phoneNumber ?? '');
    final emailCtrl =
        TextEditingController(text: profile?.email ?? '');
    final addressCtrl =
        TextEditingController(text: profile?.address ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modifier mes coordonnées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Téléphone, email et adresse actuelle uniquement.',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse actuelle',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final data = <String, dynamic>{};
                  final phone = phoneCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  final address = addressCtrl.text.trim();
                  if (phone.isNotEmpty) data['phone_number'] = phone;
                  if (email.isNotEmpty) data['email'] = email;
                  if (address.isNotEmpty) data['address'] = address;
                  if (data.isEmpty) {
                    Navigator.of(ctx).pop();
                    return;
                  }
                  final ok = await ref
                      .read(profileProvider.notifier)
                      .updateProfile(data);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Coordonnées mises à jour'
                          : 'Erreur lors de la mise à jour'),
                      backgroundColor: ok ? kGreen : Colors.red,
                    ));
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec profil
          SliverToBoxAdapter(
            child: _Header(title: l.settingsTitle, profile: profile),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Profil ────────────────────────────────────────────────
                _SectionLabel('Mon profil'),
                const SizedBox(height: 10),
                _TapTile(
                  icon: Icons.contact_phone_outlined,
                  label: 'Modifier mes coordonnées',
                  onTap: () => _showEditContactSheet(context, ref, profile),
                ),
                const SizedBox(height: 28),

                // ── Apparence ────────────────────────────────────────────
                _SectionLabel(l.settingsTheme),
                const SizedBox(height: 10),
                _ThemeSelector(current: settings.themeMode, l: l),
                const SizedBox(height: 28),

                // ── Langue ───────────────────────────────────────────────
                _SectionLabel(l.settingsLanguage),
                const SizedBox(height: 10),
                _LanguageSelector(current: settings.localeCode, l: l),
                const SizedBox(height: 28),

                // ── Support ──────────────────────────────────────────────
                _SectionLabel(l.supportTitle),
                const SizedBox(height: 10),
                _TapTile(
                  icon: Icons.help_outline,
                  label: l.supportTitle,
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 28),

                // ── À propos ─────────────────────────────────────────────
                _SectionLabel(l.settingsAbout),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.info_outline,
                  label: l.settingsVersion,
                  trailing: const Text('0.1.0',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
                const SizedBox(height: 28),

                // ── Déconnexion ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/onboarding');
                    },
                    icon: Icon(Icons.logout, color: cs.error),
                    label: Text(l.settingsLogout,
                        style: TextStyle(color: cs.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.error),
                      foregroundColor: cs.error,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final UserProfile? profile;
  const _Header({required this.title, this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (profile != null) ...[
                const SizedBox(height: 20),
                Builder(builder: (context) {
                  final p = profile!;
                  return Row(
                  children: [
                    // Avatar cliquable
                    Consumer(
                      builder: (ctx, ref, _) => GestureDetector(
                        onTap: () async {
                          final ok = await ref
                              .read(profileProvider.notifier)
                              .updateAvatar();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? 'Photo mise à jour'
                                  : 'Erreur ou annulé'),
                              backgroundColor: ok ? kGreen : Colors.grey,
                            ));
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: kGreen, width: 2),
                              ),
                              child: ClipOval(
                                child: p.avatarUrl != null
                                    ? Image.network(
                                        p.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _defaultAvatar(),
                                      )
                                    : _defaultAvatar(),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: kGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.fullName.isNotEmpty ? p.fullName : 'Utilisateur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.phoneNumber,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          if (p.city != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.5)),
                                const SizedBox(width: 3),
                                Text(
                                  p.city!,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.isProfileComplete
                            ? kGreen.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: p.isProfileComplete ? kGreen : Colors.orange,
                        ),
                      ),
                      child: Text(
                        p.isProfileComplete ? 'Complet' : 'Incomplet',
                        style: TextStyle(
                          color:
                              p.isProfileComplete ? kGreen : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme selector ────────────────────────────────────────────────────────────

class _ThemeSelector extends ConsumerWidget {
  final AppThemeMode current;
  final AppLocalizations l;
  const _ThemeSelector({required this.current, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final options = [
      (AppThemeMode.light, l.settingsThemeLight, Icons.wb_sunny_outlined),
      (AppThemeMode.dark, l.settingsThemeDark, Icons.nights_stay_outlined),
      (AppThemeMode.nightBlue, l.settingsThemeNightBlue, Icons.bedtime_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: options.map((opt) {
          final (mode, label, icon) = opt;
          final selected = current == mode;
          return ListTile(
            leading: Icon(icon,
                color: selected ? kGreen : cs.onSurface.withValues(alpha:0.6)),
            title: Text(label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? kGreen : cs.onSurface,
                )),
            trailing: selected
                ? const Icon(Icons.check_circle_rounded, color: kGreen)
                : null,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onTap: () =>
                ref.read(settingsProvider.notifier).setThemeMode(mode),
          );
        }).toList(),
      ),
    );
  }
}

// ── Language selector ─────────────────────────────────────────────────────────

class _LanguageSelector extends ConsumerWidget {
  final String? current;
  final AppLocalizations l;
  const _LanguageSelector({required this.current, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final options = [
      (null, l.settingsLanguageSystem, Icons.phone_android_outlined),
      ('fr', l.settingsLanguageFr, Icons.language),
      ('en', l.settingsLanguageEn, Icons.language),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: options.map((opt) {
          final (code, label, icon) = opt;
          final selected = current == code;
          return ListTile(
            leading: Icon(icon,
                color: selected ? kGreen : cs.onSurface.withValues(alpha:0.6)),
            title: Text(label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? kGreen : cs.onSurface,
                )),
            trailing: selected
                ? const Icon(Icons.check_circle_rounded, color: kGreen)
                : null,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onTap: () =>
                ref.read(settingsProvider.notifier).setLocale(code),
          );
        }).toList(),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.45),
          letterSpacing: 1.2,
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _InfoTile({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.onSurface.withValues(alpha: 0.6)),
        title: Text(label),
        trailing: trailing,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TapTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.onSurface.withValues(alpha: 0.6)),
        title: Text(label),
        trailing: Icon(Icons.chevron_right, color: cs.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}

Widget _defaultAvatar() => Container(
      color: kGreen.withValues(alpha: 0.2),
      child: const Icon(Icons.person, color: kGreen, size: 28),
    );
