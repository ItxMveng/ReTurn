import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/profile/providers/profile_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _gender;
  DateTime? _dob;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1930),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileDobRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await ref.read(profileProvider.notifier).updateProfile({
      'full_name': _nameCtrl.text.trim(),
      'date_of_birth': _formatDate(_dob!),
      if (_nationalIdCtrl.text.trim().isNotEmpty)
        'national_id_number': _nationalIdCtrl.text.trim(),
      'gender': _gender,
      'city': _cityCtrl.text.trim(),
      if (_regionCtrl.text.trim().isNotEmpty)
        'region': _regionCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorGeneric),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    return Scaffold(
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 30, color: kGreen),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.profileWelcome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.profileSetupSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning banner
                    _WarningBanner(message: l.profileImportanceWarning),
                    const SizedBox(height: 24),

                    // Full name
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l.profileNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l.profileNameRequired;
                        }
                        if (v.trim().length < 2) return l.profileNameTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of birth
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          key: ValueKey(_dob),
                          initialValue: _dob != null ? _formatDate(_dob!) : '',
                          decoration: InputDecoration(
                            labelText: l.profileDobLabel,
                            prefixIcon: const Icon(Icons.cake_outlined),
                            suffixIcon: const Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (_) =>
                              _dob == null ? l.profileDobRequired : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: InputDecoration(
                        labelText: l.profileGenderLabel,
                        prefixIcon: const Icon(Icons.wc_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'male',
                            child: Text(l.profileGenderMale)),
                        DropdownMenuItem(
                            value: 'female',
                            child: Text(l.profileGenderFemale)),
                        DropdownMenuItem(
                            value: 'other',
                            child: Text(l.profileGenderOther)),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                      validator: (v) =>
                          v == null ? l.profileGenderRequired : null,
                    ),
                    const SizedBox(height: 16),

                    // National ID (optional)
                    TextFormField(
                      controller: _nationalIdCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l.profileNationalIdLabel,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        helperText: l.profileNationalIdHelper,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City of birth (required)
                    TextFormField(
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l.profileCityLabel,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l.profileCityRequired : null,
                    ),
                    const SizedBox(height: 16),

                    // Region (optional)
                    TextFormField(
                      controller: _regionCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l.profileRegionLabel,
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address (optional)
                    TextFormField(
                      controller: _addressCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l.profileAddressLabel,
                        prefixIcon: const Icon(Icons.home_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text(l.profileContinue),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFCC8400), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B4400),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
