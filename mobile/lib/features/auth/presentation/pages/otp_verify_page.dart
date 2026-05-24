import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_notifier.dart';
import '../../application/auth_state.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _nodes[0].requestFocus());
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _otpCode => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length < 6) {
      _showError('Entrez les 6 chiffres du code OTP');
      return;
    }
    setState(() => _loading = true);
    final success = await ref.read(otpNotifierProvider.notifier).verifyOtp(
      phoneNumber: widget.phoneNumber,
      otpCode: code,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!success) {
      final msg = ref.read(otpNotifierProvider).whenOrNull(error: (m) => m) ?? 'Code incorrect';
      _showError(msg);
      // Vide les champs
      for (final c in _ctrls) c.clear();
      _nodes[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    setState(() => _resendCountdown = 60);
    _startCountdown();
    await ref.read(otpNotifierProvider.notifier).requestOtp(widget.phoneNumber);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Redirection automatique après vérification réussie
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.goNamed(RouteNames.home),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.onSurface),
        title: const Text('Vérification', style: TextStyle(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('Code de vérification', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 8),
              Text(
                'Code envoyé au ${widget.phoneNumber}',
                style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              // Champs OTP 6 digits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _ctrls[i],
                  focusNode: _nodes[i],
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) {
                      _nodes[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _nodes[i - 1].requestFocus();
                    }
                    if (_otpCode.length == 6) _verify();
                  },
                )),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: (_loading || _otpCode.length < 6) ? null : _verify,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Vérifier le code'),
              ),
              const SizedBox(height: 20),
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Renvoyer dans $_resendCountdown s',
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Renvoyer le code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true,
          fillColor: AppColors.surfaceVariant,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
