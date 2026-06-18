import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

class _GoogleBtn extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleBtn({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: Color(0xFF4285F4), shape: BoxShape.circle),
              child: const Text('G',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Text('Continuer avec Google',
                style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
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
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOtpLoading = otpState.maybeWhen(sending: () => true, orElse: () => false);
    final isGoogleLoading = authState.maybeWhen(loading: () => true, orElse: () => false);
    final isLoading = isOtpLoading || isGoogleLoading;

    // Navigue vers OTP quand le code est envoyé
    ref.listen<OtpState>(otpNotifierProvider, (_, next) {
      next.whenOrNull(
        sent: (phone) => context.go('/auth/otp', extra: phone),
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    // Redirige vers home si Google Sign-In réussi
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go('/declarations'),
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error)),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('DocRetour')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Entrez votre numéro de téléphone',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nous vous enverrons un code de vérification.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro (+237...)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Numéro requis';
                  if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(v.trim())) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          ref
                              .read(otpNotifierProvider.notifier)
                              .requestOtp(_phoneCtrl.text.trim());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isOtpLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Recevoir le code'),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4))),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),
              _GoogleBtn(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authNotifierProvider.notifier)
                        .signInWithGoogle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
