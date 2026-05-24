import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

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
    // Utilise OtpState pour spinner (envoi OTP)
    final otpState = ref.watch(otpNotifierProvider);
    final isLoading = otpState.maybeWhen(
      sending: () => true,
      orElse: () => false,
    );

    // Navigue vers OTP quand le code est envoyé
    ref.listen<OtpState>(otpNotifierProvider, (_, next) {
      next.whenOrNull(
        sent: (phone) => context.go('/auth/otp', extra: phone),
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
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
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Recevoir le code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
