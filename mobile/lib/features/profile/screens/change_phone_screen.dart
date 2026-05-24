import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';

/// Écran de modification du numéro de téléphone avec validation OTP
/// Flux : saisir nouveau numéro → envoi OTP → saisir code → confirmation
enum _Step { inputPhone, inputOtp, success }

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() =>
      _ChangePhoneScreenState();
}

class _ChangePhoneScreenState
    extends ConsumerState<ChangePhoneScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  _Step _step = _Step.inputPhone;
  String? _verificationId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── Étape 1 : envoyer OTP au nouveau numéro ────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _error = 'Numéro de téléphone invalide');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // On réutilise l'infrastructure Firebase OTP déjà en place
    await ref.read(authProvider.notifier).sendOtp(phone);

    final authState = ref.read(authProvider);
    authState.maybeWhen(
      codeSent: (verificationId, _, __) {
        setState(() {
          _verificationId = verificationId;
          _step = _Step.inputOtp;
          _loading = false;
        });
      },
      error: (msg) {
        setState(() {
          _error = msg;
          _loading = false;
        });
      },
      orElse: () {
        setState(() {
          _error = 'Erreur lors de l\'envoi du code';
          _loading = false;
        });
      },
    );
  }

  // ── Étape 2 : vérifier OTP et appliquer le nouveau numéro ─────────────────

  Future<void> _verifyAndApply() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Le code doit contenir 6 chiffres');
      return;
    }
    if (_verificationId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    await ref.read(authProvider.notifier).verifyOtp(
          verificationId: _verificationId!,
          code: code,
        );

    final authState = ref.read(authProvider);
    final ok = authState.maybeWhen(
      authenticated: (_, __, ___) => true,
      orElse: () => false,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (ok) {
          _step = _Step.success;
        } else {
          _error = 'Code incorrect ou expiré';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Changer le numéro'),
        backgroundColor: cs.brightness == Brightness.light
            ? const Color(0xFF0D2B1F)
            : cs.surfaceContainerHighest,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _step == _Step.success
            ? _SuccessView(
                phone: _phoneCtrl.text.trim(),
                onDone: () => context.pop(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicateur d'étape
                  _StepIndicator(
                    currentStep: _step == _Step.inputPhone ? 1 : 2,
                    totalSteps: 2,
                  ),
                  const SizedBox(height: 28),

                  if (_step == _Step.inputPhone) ...[
                    const Text(
                      'Nouveau numéro de téléphone',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un code de vérification vous sera envoyé par SMS.',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+237 6XX XXX XXX',
                        prefixIcon:
                            const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Code de vérification',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrez le code à 6 chiffres reçu sur ${_phoneCtrl.text.trim()}',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • • • •',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(
                          () => _step = _Step.inputPhone),
                      child: Text(
                          'Changer le numéro',
                          style: TextStyle(
                              color:
                                  cs.onSurface.withValues(
                                      alpha: 0.5))),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_step == _Step.inputPhone
                              ? _sendOtp
                              : _verifyAndApply),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white))
                          : Text(
                              _step == _Step.inputPhone
                                  ? 'Envoyer le code'
                                  : 'Confirmer',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i < currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 4,
            decoration: BoxDecoration(
              color: active ? kGreen : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String phone;
  final VoidCallback onDone;
  const _SuccessView({required this.phone, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle, color: kGreen, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Numéro mis à jour !',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            phone,
            style: const TextStyle(
                fontSize: 16, color: kGreen, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retour au profil'),
          ),
        ],
      ),
    );
  }
}
