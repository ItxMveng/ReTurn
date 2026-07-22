import 'dart:async';

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
  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Masque le numéro : +237699887766 → +237 6•• •• •• 66
  String get _maskedPhone {
    final p = widget.phoneNumber;
    if (p.length < 6) return p;
    return '${p.substring(0, p.length - 8).padRight(p.length - 2, '•')}'
        '${p.substring(p.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sms_outlined, color: cs.primary, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vérification',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Code envoyé au $_maskedPhone',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '••••••',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Renvoyer le code dans 0:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    )
                  : TextButton(
                      onPressed: () {
                        ref
                            .read(otpNotifierProvider.notifier)
                            .requestOtp(widget.phoneNumber);
                        _startCountdown();
                      },
                      child: const Text('Renvoyer le code'),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => ref.read(otpNotifierProvider.notifier).verifyOtp(
                        phoneNumber: widget.phoneNumber,
                        otpCode: _otpCtrl.text.trim(),
                      ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
