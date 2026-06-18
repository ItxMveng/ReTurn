import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpVerifyScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Utilise OtpState pour le chargement (pas AuthState)
    final otpState = ref.watch(otpNotifierProvider);
    final isLoading = otpState.maybeWhen(
      verifying: () => true,
      orElse: () => false,
    );

    // Redirige après auth réussie
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go('/declarations'),
      );
    });

    // Affiche erreur OTP
    ref.listen<OtpState>(otpNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Text(
              'Code envoyé au ${widget.phoneNumber}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'Code OTP',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => ref.read(otpNotifierProvider.notifier).verifyOtp(
                        phoneNumber: widget.phoneNumber,
                        otpCode: _otpCtrl.text.trim(),
                      ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Vérifier'),
            ),
          ],
        ),
      ),
    );
  }
}
