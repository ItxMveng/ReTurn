import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 9;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).sendOtp(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final isLoading =
        authState.maybeWhen(loading: () => true, orElse: () => false);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    ref.listen(authProvider, (_, next) {
      next.maybeWhen(
        codeSent: (verificationId, phoneNumber, _) {
          context.push('/auth/otp', extra: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
          });
        },
        authenticated: (_, __, ___) => context.go('/home'),
        error: (message, __) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: cs.error,
          ));
        },
        orElse: () {},
      );
    });

    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    return Scaffold(
      body: Column(
        children: [
          // Header
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
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/onboarding'),
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
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/logo_ReTurn-removebg.png',
                      height: 52,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.find_in_page, size: 52, color: kGreen),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l.phoneInputTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.phoneInputSubtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.phoneInputLabel,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _controller,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _PhoneFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🇨🇲',
                                  style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                '+237',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                  width: 1,
                                  height: 22,
                                  color: cs.outline),
                            ],
                          ),
                        ),
                        hintText: 'XX XX XX XX XX',
                      ),
                      validator: (v) {
                        final digits =
                            (v ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return l.phoneValidRequired;
                        if (digits.length != 9) return l.phoneValidLength;
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed:
                          (!_isValid || isLoading) ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Text(l.phoneInputReceive),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: cs.outline, thickness: 1.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Text(l.phoneInputOr,
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                  fontSize: 13)),
                        ),
                        Expanded(
                            child: Divider(
                                color: cs.outline, thickness: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(authProvider.notifier)
                              .signInWithGoogle(),
                      icon: const _GoogleLogo(),
                      label: Text(l.phoneInputGoogle),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        l.phoneInputTerms,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.35),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.5, 2.6, true, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), 2.1, 1.5, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), 3.6, 1.0, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r), 4.6, 1.68, true, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.65, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
        Rect.fromLTWH(cx, cy - r * 0.15, r * 0.95, r * 0.3), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 9; i++) {
      if (i > 0 && i % 2 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
