import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/profile/providers/profile_provider.dart';

/// Écran d'édition du profil avec upload avatar + champs modifiables
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loadingAvatar = false;
  bool _loadingSave = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      _nameCtrl.text = profile.fullName;
      _cityCtrl.text = profile.city ?? '';
      _regionCtrl.text = profile.region ?? '';
      _addressCtrl.text = profile.address ?? '';
      _emailCtrl.text = profile.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Avatar picker ──────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (xFile == null) return;
    setState(() {
      _pickedImage = xFile;
      _loadingAvatar = true;
    });
    final ok =
        await ref.read(profileProvider.notifier).updateAvatarFromFile(xFile);
    if (mounted) {
      setState(() => _loadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Photo de profil mise à jour ✅'
            : 'Échec de l\'upload de la photo'),
        backgroundColor: ok ? kGreen : Colors.red,
      ));
    }
  }

  // ── Email : vérif unicité avant sauvegarde ─────────────────────────────────

  Future<bool> _checkEmailUnique(String email) async {
    if (email.isEmpty) return true;
    final currentEmail =
        ref.read(profileProvider).valueOrNull?.email ?? '';
    if (email == currentEmail) return true; // pas changé
    return ref.read(profileProvider.notifier).checkEmailAvailable(email);
  }

  // ── Sauvegarde ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingSave = true);

    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) {
      final available = await _checkEmailUnique(email);
      if (!available) {
        setState(() => _loadingSave = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Cette adresse email est déjà utilisée par un autre compte.'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }
    }

    final ok = await ref.read(profileProvider.notifier).updateProfile({
      'full_name': _nameCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      if (_regionCtrl.text.trim().isNotEmpty)
        'region': _regionCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (email.isNotEmpty) 'email': email,
    });

    if (mounted) {
      setState(() => _loadingSave = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour ✅'),
          backgroundColor: kGreen,
        ));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider).valueOrNull;
    final avatarUrl = _pickedImage != null
        ? null
        : profile?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: cs.brightness == Brightness.light
            ? const Color(0xFF0D2B1F)
            : cs.surfaceContainerHighest,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loadingSave ? null : _save,
            child: _loadingSave
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _loadingAvatar ? null : _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: kGreen.withValues(alpha: 0.15),
                        backgroundImage: _pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                                as ImageProvider
                            : (avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null),
                        child: _pickedImage == null &&
                                (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Icons.person,
                                size: 52, color: kGreen)
                            : null,
                      ),
                      if (_loadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: cs.surface, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Appuyer pour changer la photo',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 28),

              // ── Champ téléphone → OTP ───────────────────────────
              _SectionTitle('Numéro de téléphone'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile?.phoneNumber ?? '—',
                        style: TextStyle(
                            color: cs.onSurface, fontSize: 15),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/profile/change-phone'),
                      child: const Text('Modifier',
                          style: TextStyle(
                              color: kGreen,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Email ────────────────────────────────────────────
              _SectionTitle('Adresse email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ex: prenom@gmail.com',
                  prefixIcon:
                      const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final emailRx = RegExp(
                        r'^[\w.+-]+@[\w-]+\.[\w.]+$');
                    if (!emailRx.hasMatch(v)) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Nom complet ──────────────────────────────────────
              _SectionTitle('Nom complet'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 2)
                        ? 'Nom requis (min. 2 caractères)'
                        : null,
              ),
              const SizedBox(height: 20),

              // ── Ville ────────────────────────────────────────────
              _SectionTitle('Ville'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Région ──────────────────────────────────────────
              _SectionTitle('Région (optionnel)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _regionCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Adresse ─────────────────────────────────────────
              _SectionTitle('Adresse (optionnel)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingSave ? null : _save,
                  icon: _loadingSave
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer les modifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey));
  }
}
