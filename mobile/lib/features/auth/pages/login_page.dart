import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_notifier.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtr = TextEditingController();
  final _passCtr = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .login(_phoneCtr.text.trim(), _passCtr.text);
    if (ok && mounted) context.go('/declarations');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final cs = Theme.of(context).colorScheme;
    final loading = state.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(children: [
                  Icon(Icons.find_in_page_rounded,
                      color: cs.primary, size: 32),
                  const SizedBox(width: 10),
                  Text('ReTurn',
                      style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: cs.primary)),
                ]),
                const SizedBox(height: 40),
                const Text('Connexion',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 24)),
                const SizedBox(height: 8),
                Text('Bienvenue sur ReTurn',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 15)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneCtr,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().length < 9)
                      ? 'Numéro invalide'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtr,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min. 6 caractères' : null,
                ),
                if (state.error != null) ...
                  [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline,
                            color: cs.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(state.error!,
                                style: TextStyle(
                                    color: cs.error, fontSize: 13))),
                      ]),
                    )
                  ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text.rich(TextSpan(children: [
                      const TextSpan(text: 'Pas encore de compte ? '),
                      TextSpan(
                          text: 'Créer un compte',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700)),
                    ])),
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
