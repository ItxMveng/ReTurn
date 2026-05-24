import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  int _step = 0; // 0 = infos, 1 = OTP

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: Commit B — implémenter AuthNotifier
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _loading = false; _step = 1; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.onSurface, onPressed: () {
          if (_step > 0) {
            setState(() => _step = 0);
          } else {
            context.goNamed(RouteNames.login);
          }
        }),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _step == 0 ? _buildForm() : _buildOtpStep(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer un compte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text('Rejoignez ReTurn pour retrouver vos documents', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Nom requis (min. 2 caractères)' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Téléphone', hintText: '+237 6XX XXX XXX', prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) => (v == null || v.trim().length < 9) ? 'Numéro invalide' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 8) ? 'Minimum 8 caractères' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline_rounded)),
            validator: (v) => v != _passwordCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Créer mon compte'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed(RouteNames.login),
              child: const Text('Déjà un compte ? Se connecter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vérification OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 6),
        Text('Un code a été envoyé au ${_phoneCtrl.text}', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 32),
        TextFormField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(labelText: 'Code OTP', counterText: ''),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => context.goNamed(RouteNames.home),
          child: const Text('Vérifier'),
        ),
      ],
    );
  }
}
