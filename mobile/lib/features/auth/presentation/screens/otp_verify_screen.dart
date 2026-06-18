import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:return_mobile/core/theme/app_theme.dart';
import 'package:return_mobile/features/auth/application/auth_notifier.dart';
import 'package:return_mobile/features/auth/application/auth_state.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerifyScreen({
    super.key,
    required this.phoneNumber,
    // verificationId ignoré — architecture OTP backend
    String? verificationId,
  });

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNodes.first.requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _maskedPhone {
    final p = widget.phoneNumber;
    if (p.length < 6) return p;
    return '${p.substring(0, 4)} XX XX ${p.substring(p.length - 2)}';
  }

  Future<void> _verify() async {
    if (_code.length < 6) return;
    await ref.read(otpNotifierProvider.notifier).verifyOtp(
        phoneNumber: widget.phoneNumber, otpCode: _code);
  }

  void _shakeAndReset() {
    _shakeController.forward(from: 0);
    for (final c in _controllers) { c.clear(); }
    _focusNodes.first.requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes.last.requestFocus();
      _verify();
      return;
    }
    if (index < 5) _focusNodes[index + 1].requestFocus();
    if (_code.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final otpState = ref.watch(otpNotifierProvider);
    final isLoading = otpState.maybeWhen(
      verifying: () => true,
      orElse: () => false,
    );

    // Redirection après auth réussie
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go('/declarations'),
      );
    });

    // Écoute erreurs OTP
    ref.listen<OtpState>(otpNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (message) {
          _shakeAndReset();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: cs.error));
        },
      );
    });

    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Vérification OTP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14),
                          children: [
                            const TextSpan(text: 'Code envoyé au '),
                            TextSpan(
                              text: _maskedPhone,
                              style: const TextStyle(
                                  color: kGreen,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── OTP cells ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0), child: child),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => _OtpCell(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) => _onDigitChanged(i, v),
                        enabled: !isLoading,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Resend ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _secondsLeft > 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 6),
                          Text(
                            'Renvoyer dans 0:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4),
                                fontSize: 14),
                          ),
                        ],
                      )
                    : Center(
                        child: TextButton(
                          onPressed: () {
                            ref.read(otpNotifierProvider.notifier)
                                .requestOtp(widget.phoneNumber);
                            _startTimer();
                          },
                          child: const Text('Renvoyer le code'),
                        ),
                      ),
              ),

              // ── Verify button ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: ElevatedButton(
                  onPressed: (_code.length < 6 || isLoading) ? null : _verify,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Vérifier le code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: cs.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outline, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreen, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: cs.onSurface.withValues(alpha: 0.15)),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
