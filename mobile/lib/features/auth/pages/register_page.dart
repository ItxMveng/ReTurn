import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_notifier.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtr = TextEditingController();
  final _prenomCtr = TextEditingController();
  final _phoneCtr = TextEditingController();
  final _passCtr = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nomCtr.dispose();
    _prenomCtr.dispose();
    _phoneCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authNotifierProvider.notifier).register(
        _phoneCtr.text.trim(),
        _passCtr.text,
        _nomCtr.text.trim(),
        _prenomCtr.text.trim());
    if (ok && mounted) context.go('/declarations');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final cs = Theme.of(context).colorScheme;
    final loading = state.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomCtr,
                      decoration:
                          const InputDecoration(labelText: 'Nom'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prenomCtr,
                      decoration:
                          const InputDecoration(labelText: 'Prénom'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtr,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
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
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Min. 6 caractères'
                      : null,
                ),
                if (state.error != null) ...
                  [
                    const SizedBox(height: 12),
                    Text(state.error!,
                        style: TextStyle(color: cs.error, fontSize: 13)),
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
                      : const Text("S'inscrire"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
