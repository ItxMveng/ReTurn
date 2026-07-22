import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/biometric_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/app_loader.dart';
import '../../auth/application/auth_notifier.dart';
import '../providers/profile_provider.dart';

/// Champs suivis par la barre de progression du profil (6 au total).
/// Les 5 premiers conditionnent le badge « Complet » côté backend ;
/// le numéro CNI est optionnel mais compté dans la progression.
List<({String label, bool filled})> _profileFields(UserProfile p) => [
      (label: 'Nom complet', filled: p.fullName.trim().isNotEmpty),
      (
        label: 'Téléphone ou email',
        filled: p.phoneNumber.trim().isNotEmpty ||
            (p.email ?? '').trim().isNotEmpty
      ),
      (
        label: 'Date de naissance',
        filled: (p.dateOfBirth ?? '').trim().isNotEmpty
      ),
      (label: 'Genre', filled: (p.gender ?? '').trim().isNotEmpty),
      (label: 'Ville', filled: (p.city ?? '').trim().isNotEmpty),
      (
        label: 'Numéro CNI / Passeport',
        filled: (p.nationalIdNumber ?? '').trim().isNotEmpty
      ),
    ];

/// Bottom sheet « Complétez votre profil en 1 minute » — non-ignorable,
/// affiché au premier lancement post-inscription si le profil est incomplet.
Future<void> showCompleteProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _CompleteProfilePrompt(),
  );
}

/// Contenu du bottom sheet non-ignorable de complétion post-inscription.
class _CompleteProfilePrompt extends ConsumerWidget {
  const _CompleteProfilePrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    // Profil devenu complet (ou déconnecté) → on libère l'utilisateur.
    if (profile == null || profile.isProfileComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    final missing =
        _profileFields(profile).where((f) => !f.filled).take(4).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_pin_circle_outlined,
                  color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Complétez votre profil en 1 minute',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Ces informations servent à vérifier votre identité lors de '
              'la récupération d\'un document.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          ...missing.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.radio_button_unchecked,
                      size: 18, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(f.label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => _EditProfileSheet(profile: profile),
                );
              },
              child: const Text('Compléter maintenant'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page unique « Profil » : informations, apparence, langue, aide et
/// déconnexion. Remplace l'ancien duo onglet Profil + écran Paramètres.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const AppLoader(message: 'Chargement du profil…'),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(profileProvider),
          onLogout: () => _logout(context, ref),
        ),
        data: (profile) {
          if (profile == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/auth/phone'));
            return const SizedBox.shrink();
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }

  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go('/auth/phone');
  }

  /// RGPD (F-04) — suppression définitive du compte et des données.
  static Future<void> _deleteAccount(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est définitive et irréversible. Votre compte, vos '
          'déclarations, vos matchs et vos messages seront supprimés '
          'conformément à votre droit à l\'effacement (RGPD/CPDP).\n\n'
          'Voulez-vous vraiment continuer ?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref.read(profileProvider.notifier).deleteAccount();
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suppression impossible, réessayez.')),
        );
      }
      return;
    }
    await ref.read(authNotifierProvider.notifier).deleteFirebaseAccountAndLogout();
    if (context.mounted) context.go('/auth/phone');
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(profile: profile)),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Progression de complétion ────────────────────────────
              if (!profile.isProfileComplete) ...[
                _CompletionCard(
                  profile: profile,
                  onFieldTap: () => _showEditSheet(context, ref, profile),
                ),
                const SizedBox(height: 24),
              ],

              // ── Mon profil ───────────────────────────────────────────
              const _SectionLabel('Mon profil'),
              const SizedBox(height: 10),
              _Card(children: [
                _Tile(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Modifier / compléter mon profil',
                  onTap: () => _showEditSheet(context, ref, profile),
                ),
                const _Sep(),
                _Tile(
                  icon: Icons.history,
                  label: 'Mes restitutions',
                  onTap: () => context.push('/restitutions'),
                ),
                const _Sep(),
                _Tile(
                  icon: Icons.place_outlined,
                  label: 'Zones de récupération',
                  onTap: () => context.push('/zones'),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Apparence ────────────────────────────────────────────
              const _SectionLabel('Apparence'),
              const SizedBox(height: 10),
              _Card(children: [
                _ThemeOption(
                  mode: AppThemeMode.light,
                  current: settings.themeMode,
                  icon: Icons.wb_sunny_outlined,
                  label: 'Clair',
                ),
                const _Sep(),
                _ThemeOption(
                  mode: AppThemeMode.dark,
                  current: settings.themeMode,
                  icon: Icons.nights_stay_outlined,
                  label: 'Sombre',
                ),
              ]),
              const SizedBox(height: 28),

              // ── Langue ───────────────────────────────────────────────
              const _SectionLabel('Langue'),
              const SizedBox(height: 10),
              _Card(children: [
                _LangOption(
                  code: null,
                  current: settings.localeCode,
                  icon: Icons.phone_android_outlined,
                  label: 'Langue du système',
                ),
                const _Sep(),
                _LangOption(
                  code: 'fr',
                  current: settings.localeCode,
                  icon: Icons.language,
                  label: 'Français',
                ),
                const _Sep(),
                _LangOption(
                  code: 'en',
                  current: settings.localeCode,
                  icon: Icons.language,
                  label: 'English',
                ),
              ]),
              const SizedBox(height: 28),

              // ── Sécurité ─────────────────────────────────────────────
              const _SectionLabel('Sécurité'),
              const SizedBox(height: 10),
              const _Card(children: [_BiometricTile()]),
              const SizedBox(height: 28),

              // ── Aide & support ───────────────────────────────────────
              const _SectionLabel('Aide & support'),
              const SizedBox(height: 10),
              _Card(children: [
                _Tile(
                  icon: Icons.help_outline,
                  label: 'Aide & FAQ',
                  onTap: () => context.push('/help'),
                ),
                const _Sep(),
                _Tile(
                  icon: Icons.support_agent,
                  label: 'Contacter le support',
                  onTap: () => context.push('/support'),
                ),
                const _Sep(),
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Confidentialité',
                  onTap: () => context.push('/privacy'),
                ),
              ]),
              const SizedBox(height: 28),

              // ── À propos ─────────────────────────────────────────────
              const _SectionLabel('À propos'),
              const SizedBox(height: 10),
              _Card(children: [
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: AppColors.onSurfaceVariant),
                  title: const Text('Version'),
                  trailing: Text('1.0.0',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Déconnexion ──────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => ProfilePage._logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Zone de danger'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ProfilePage._deleteAccount(context, ref),
                icon: const Icon(Icons.delete_forever_outlined,
                    color: AppColors.error),
                label: const Text('Supprimer mon compte (RGPD)',
                    style: TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, UserProfile p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditProfileSheet(profile: p),
    );
  }
}

/// Barre de progression du profil : « X/6 champs renseignés » + liste
/// cliquable des champs manquants (chaque champ ouvre le formulaire).
class _CompletionCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onFieldTap;
  const _CompletionCard({required this.profile, required this.onFieldTap});

  @override
  Widget build(BuildContext context) {
    final fields = _profileFields(profile);
    final filled = fields.where((f) => f.filled).length;
    final missing = fields.where((f) => !f.filled).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.task_alt, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('$filled/${fields.length} champs renseignés',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: filled / fields.length,
              minHeight: 8,
              backgroundColor: AppColors.outline.withValues(alpha: 0.4),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missing
                .map((f) => ActionChip(
                      avatar: Icon(Icons.add_circle_outline,
                          size: 16, color: AppColors.primary),
                      label: Text(f.label,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primary)),
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.06),
                      onPressed: onFieldTap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Feuille « Compléter / modifier mon profil ».
/// - Nom complet, ville, adresse : modifiables (complétion du profil).
/// - Téléphone & email DÉJÀ renseignés : lecture seule (vérification pro requise).
/// - Téléphone OU email manquant : ajoutable (permet la connexion croisée
///   OTP ⇄ Google sur le même compte).
class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _nameCtrl = TextEditingController(text: widget.profile.fullName);
  late final _cityCtrl = TextEditingController(text: widget.profile.city ?? '');
  late final _addressCtrl =
      TextEditingController(text: widget.profile.address ?? '');
  late final _idCtrl =
      TextEditingController(text: widget.profile.nationalIdNumber ?? '');
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late DateTime? _dob = widget.profile.dateOfBirth != null
      ? DateTime.tryParse(widget.profile.dateOfBirth!)
      : null;
  late String? _gender = _genders.contains(widget.profile.gender)
      ? widget.profile.gender
      : null;
  bool _saving = false;
  String? _error;

  static const _genders = ['Homme', 'Femme', 'Autre'];

  bool get _hasPhone => widget.profile.phoneNumber.trim().isNotEmpty;
  bool get _hasEmail => (widget.profile.email ?? '').trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    // Âge minimum : 16 ans.
    final lastDate = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: lastDate,
      helpText: 'Votre date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _normalizePhone(String v) {
    final p = v.trim().replaceAll(RegExp(r'\s'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('237')) return '+$p';
    return '+237$p';
  }

  Future<void> _save() async {
    final p = widget.profile;

    // Champs d'identité (jamais en conflit avec un autre compte).
    final identity = <String, dynamic>{};
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty && name != p.fullName) identity['full_name'] = name;
    if (_cityCtrl.text.trim() != (p.city ?? '')) {
      identity['city'] = _cityCtrl.text.trim();
    }
    if (_addressCtrl.text.trim() != (p.address ?? '')) {
      identity['address'] = _addressCtrl.text.trim();
    }
    if (_dob != null && _isoDate(_dob!) != (p.dateOfBirth ?? '')) {
      identity['date_of_birth'] = _isoDate(_dob!);
    }
    if (_gender != null && _gender != p.gender) {
      identity['gender'] = _gender;
    }
    if (_idCtrl.text.trim() != (p.nationalIdNumber ?? '') &&
        _idCtrl.text.trim().isNotEmpty) {
      identity['national_id_number'] = _idCtrl.text.trim();
    }

    // Coordonnées (peuvent renvoyer 409 si déjà prises par un autre compte).
    final contact = <String, dynamic>{};
    if (!_hasEmail && _emailCtrl.text.trim().isNotEmpty) {
      contact['email'] = _emailCtrl.text.trim();
    }
    if (!_hasPhone && _phoneCtrl.text.trim().isNotEmpty) {
      contact['phone_number'] = _normalizePhone(_phoneCtrl.text.trim());
    }

    if (identity.isEmpty && contact.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final notifier = ref.read(profileProvider.notifier);

    // 1) L'identité d'abord : un conflit de téléphone/email ne doit JAMAIS
    //    bloquer la complétion du profil (date de naissance, genre, ville…).
    if (identity.isNotEmpty) {
      final err = await notifier.updateProfile(identity);
      if (!mounted) return;
      if (err != null) {
        // La feuille reste ouverte : l'utilisateur voit l'erreur et corrige.
        setState(() {
          _saving = false;
          _error = err;
        });
        return;
      }
    }

    // 2) Puis les coordonnées, séparément.
    if (contact.isNotEmpty) {
      final err = await notifier.updateProfile(contact);
      if (!mounted) return;
      if (err != null) {
        setState(() {
          _saving = false;
          _error = identity.isNotEmpty
            ? 'Vos informations ont été enregistrées ✓ — mais : $err '
                'Effacez ce champ ou utilisez une autre coordonnée.'
            : err;
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('Profil mis à jour'),
      ]),
      backgroundColor: Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mon profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Complétez vos informations. La photo se change depuis l\'avatar.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Nom : modifiable seulement tant qu'il n'est pas renseigné
            // (une fois rempli, il devient officiel et non modifiable).
            if (widget.profile.fullName.trim().isNotEmpty)
              _ReadOnlyField(
                label: 'Nom complet',
                value: widget.profile.fullName,
                icon: Icons.badge_outlined,
              )
            else
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet (nom et prénom)',
                  helperText: 'Non modifiable une fois enregistré.',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            const SizedBox(height: 14),

            // ── Téléphone : lecture seule si présent, ajoutable sinon ──
            if (_hasPhone)
              _ReadOnlyField(
                label: 'Numéro de téléphone',
                value: widget.profile.phoneNumber,
                icon: Icons.phone_outlined,
              )
            else
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Ajouter un numéro (+237…)',
                  helperText: 'Pour vous connecter aussi par SMS.',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            const SizedBox(height: 14),

            // ── Email : lecture seule si présent, ajoutable sinon ──
            if (_hasEmail)
              _ReadOnlyField(
                label: 'Email',
                value: widget.profile.email!,
                icon: Icons.email_outlined,
              )
            else
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Ajouter un email',
                  helperText: 'Pour vous connecter aussi via Google.',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            const SizedBox(height: 14),

            // ── Date de naissance (requise pour la vérification) ──
            InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  helperText: 'Utilisée pour vérifier votre identité.',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _dob != null ? _formatDate(_dob!) : 'Sélectionner…',
                  style: TextStyle(
                    fontSize: 16,
                    color: _dob != null
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Genre ──
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Genre',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: _genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ville',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse actuelle',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // ── Numéro CNI / Passeport (optionnel) ──
            TextField(
              controller: _idCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Numéro CNI / Passeport',
                helperText: 'Optionnel — accélère la vérification.',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
            ),
            // ── Erreur inline : la feuille reste ouverte pour corriger ──
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.onSurface))),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ en lecture seule (verrouillé) — pour téléphone/email déjà vérifiés.
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: false,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.lock_outline, size: 18),
        helperText: 'Vérification requise pour modifier.',
      ),
    );
  }
}

// ── Header (avatar + identité + complétude) ─────────────────────────────────────
class _Header extends ConsumerWidget {
  final UserProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradColors = isDark
        ? [Theme.of(context).colorScheme.surface, AppColors.surface]
        : const [Color(0xFF01353A), Color(0xFF014A4F)];

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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profil',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ok = await ref
                          .read(profileProvider.notifier)
                          .updateAvatar();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(ok ? 'Photo mise à jour' : 'Annulé'),
                          backgroundColor:
                              ok ? AppColors.primary : Colors.grey,
                        ));
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: profile.avatarUrl != null
                                ? Image.network(mediaUrl(profile.avatarUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _defaultAvatar())
                                : _defaultAvatar(),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : 'Utilisateur',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.phoneNumber.isNotEmpty
                              ? profile.phoneNumber
                              : (profile.email ?? ''),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13),
                        ),
                        if (profile.city != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.location_on_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(profile.city!,
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12)),
                          ]),
                        ],
                        const SizedBox(height: 6),
                        _Reputation(score: profile.scoreReputation),
                      ],
                    ),
                  ),
                  _Badge(complete: profile.isProfileComplete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Réputation utilisateur (F-05) — score 0–10 affiché en étoiles + valeur.
class _Reputation extends StatelessWidget {
  final double score; // 0–10
  const _Reputation({required this.score});

  @override
  Widget build(BuildContext context) {
    final stars = (score / 2).clamp(0, 5); // 0–10 → 0–5
    return Row(children: [
      ...List.generate(5, (i) {
        final IconData icon;
        if (stars >= i + 1) {
          icon = Icons.star_rounded;
        } else if (stars >= i + 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: 15, color: Colors.amber);
      }),
      const SizedBox(width: 6),
      Text('${score.toStringAsFixed(1)}/10',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final bool complete;
  const _Badge({required this.complete});

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.primary : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(complete ? 'Complet' : 'Incomplet',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

Widget _defaultAvatar() => Container(
      color: AppColors.primaryContainer,
      child: Icon(Icons.person, color: AppColors.primary, size: 30),
    );

// ── Sélecteurs thème / langue ───────────────────────────────────────────────────
class _ThemeOption extends ConsumerWidget {
  final AppThemeMode mode;
  final AppThemeMode current;
  final IconData icon;
  final String label;
  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = mode == current;
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.onSurface)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () => ref.read(settingsProvider.notifier).setThemeMode(mode),
    );
  }
}

class _LangOption extends ConsumerWidget {
  final String? code;
  final String? current;
  final IconData icon;
  final String label;
  const _LangOption({
    required this.code,
    required this.current,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = code == current;
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.onSurface)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () => ref.read(settingsProvider.notifier).setLocale(code),
    );
  }
}

// ── Verrouillage biométrique (F-03) ─────────────────────────────────────────────
class _BiometricTile extends ConsumerWidget {
  const _BiometricTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(biometricEnabledProvider);
    return SwitchListTile(
      value: enabled,
      activeThumbColor: AppColors.primary,
      secondary: Icon(Icons.fingerprint, color: AppColors.primary),
      title: Text('Déverrouillage biométrique',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface)),
      subtitle: Text('Empreinte ou visage à l\'ouverture',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
      onChanged: (v) async {
        final messenger = ScaffoldMessenger.of(context);
        if (v) {
          if (!await BiometricService.isAvailable()) {
            messenger.showSnackBar(const SnackBar(
                content: Text(
                    'Aucune biométrie configurée sur cet appareil.')));
            return;
          }
          final ok = await BiometricService.authenticate(
              reason: 'Activez le verrouillage biométrique');
          if (!ok) return;
        }
        await ref.read(biometricEnabledProvider.notifier).setEnabled(v);
      },
    );
  }
}

// ── Briques génériques ──────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.2),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(children: children),
      );
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16);
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface)),
        trailing: Icon(Icons.chevron_right,
            color: AppColors.onSurfaceVariant),
        onTap: onTap,
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;
  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Impossible de charger le profil',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
            TextButton(
                onPressed: onLogout, child: const Text('Se déconnecter')),
          ],
        ),
      ),
    );
  }
}
