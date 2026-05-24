import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_notifier.dart';
import '../../application/auth_state.dart';
import 'otp_verify_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
    otpState.when(
      idle: () {},
      sending: () {},
      sent: (phone) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OtpVerifyPage(phoneNumber: phone)),
        );
      },
      verifying: () {},
      verified: () {},
      error: (msg) => _showError(msg),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rediriger si déjà authentifié
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.goNamed(RouteNames.home),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                // Logo
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.find_in_page_rounded, color: AppColors.onPrimary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text('ReTurn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 48),
                const Text('Connexion', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                const Text(
                  'Entrez votre numéro de téléphone.\nNous vous enverrons un code de vérification.',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 36),
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
                    if (cleaned.length < 9) return 'Numéro invalide (min. 9 chiffres)';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _requestOtp,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Recevoir le code OTP'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => context.goNamed(RouteNames.register),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14),
                        children: [
                          TextSpan(text: 'Pas de compte ? ', style: TextStyle(color: AppColors.onSurfaceVariant)),
                          TextSpan(text: 'Créer un compte', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
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
