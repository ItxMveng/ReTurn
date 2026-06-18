import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:return_mobile/core/theme/app_theme.dart';
import 'package:return_mobile/features/auth/application/auth_notifier.dart';
import 'package:return_mobile/features/auth/application/auth_state.dart';

// ─── Widget : bouton "Se connecter avec Google" ────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleSignInButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: cs.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
            child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Text(
            'Continuer avec Google',
            style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(otpNotifierProvider.notifier).requestOtp(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOtpLoading = otpState.maybeWhen(sending: () => true, orElse: () => false);
    final isGoogleLoading = authState.maybeWhen(loading: () => true, orElse: () => false);
    final isLoading = isOtpLoading || isGoogleLoading;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // Redirection si déjà authentifié (OTP ou Google)
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go('/declarations'),
        error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: cs.error),
        ),
      );
    });

    // Navigation vers OTP quand code envoyé
    ref.listen<OtpState>(otpNotifierProvider, (_, next) {
      next.whenOrNull(
        sent: (phone) {
          context.push('/auth/otp', extra: {
            'phoneNumber': phone,
          });
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: cs.error,
          ));
        },
      );
    });

    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    return Scaffold(
      body: Column(
        children: [
          // Header
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/onboarding'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.find_in_page, size: 52, color: kGreen),
                    const SizedBox(height: 20),
                    const Text(
                      'Votre numéro de téléphone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nous vous enverrons un code de vérification.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Numéro de téléphone',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _controller,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: '+237 ',
                        hintText: '6XX XXX XXX',
                      ),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return 'Numéro requis';
                        if (digits.length < 9) return 'Numéro invalide (9 chiffres min.)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: (!_isValid || isLoading) ? null : _submit,
                      child: isOtpLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Recevoir le code'),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ]),
                    const SizedBox(height: 20),
                    _GoogleSignInButton(
                      onPressed: isLoading
                          ? null
                          : () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'En continuant, vous acceptez nos conditions d\'utilisation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.35),
                            fontSize: 12),
                      ),
                    ),
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
