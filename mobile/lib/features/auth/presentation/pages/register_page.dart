import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_notifier.dart';
import '../../application/auth_state.dart';
import 'otp_verify_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final phone = _phoneCtrl.text.trim();
    await ref.read(otpNotifierProvider.notifier).requestOtp(phone);
    if (!mounted) return;
    setState(() => _loading = false);
    final otpState = ref.read(otpNotifierProvider);
    otpState.whenOrNull(
      sent: (phone) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpVerifyPage(phoneNumber: phone)),
      ),
      error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(authenticated: (_) => context.goNamed(RouteNames.home));
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: AppColors.onSurface,
          onPressed: () => context.goNamed(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Créer un compte', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                const Text(
                  'Rejoignez ReTurn pour retrouver et restituer des documents perdus.',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 32),
                // Infos visuelles sur le processus
                const _ProcessStep(number: '1', label: 'Entrez votre numéro', done: false),
                const SizedBox(height: 8),
                const _ProcessStep(number: '2', label: 'Vérifiez par code OTP', done: false),
                const SizedBox(height: 8),
                const _ProcessStep(number: '3', label: 'Complétez votre profil', done: false),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '+237 6XX XXX XXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Numéro requis';
                    final cleaned = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
                    if (cleaned.length < 9) return 'Numéro invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _requestOtp,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Continuer'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.goNamed(RouteNames.login),
                    child: const Text('Déjà un compte ? Se connecter', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({required this.number, required this.label, required this.done});
  final String number;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? AppColors.success : AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary)
                : Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: done ? AppColors.onSurfaceVariant : AppColors.onSurface, fontWeight: done ? FontWeight.w400 : FontWeight.w500)),
      ],
    );
  }
}
