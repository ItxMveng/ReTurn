import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_notifier.dart';
import '../application/auth_state.dart';

// ─── Icône Google multicolore ─────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(painter: _GoogleGPainter(), size: const Size(26, 26)),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.36;

    final blue   = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18..strokeCap = StrokeCap.butt;
    final red    = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18..strokeCap = StrokeCap.butt;
    final yellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18..strokeCap = StrokeCap.butt;
    final green  = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18..strokeCap = StrokeCap.butt;

    const deg = 3.14159265 / 180;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    canvas.drawArc(rect, -90 * deg, 130 * deg, false, blue);
    canvas.drawArc(rect,  40 * deg,  85 * deg, false, green);
    canvas.drawArc(rect, 125 * deg,  95 * deg, false, yellow);
    canvas.drawArc(rect, 220 * deg,  95 * deg, false, red);

    // Barre horizontale du G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barH = size.height * 0.16;
    final barY = cy - barH / 2;
    final barLeft  = cx;
    final barRight = cx + r + size.width * 0.09;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(barLeft, barY, barRight, barY + barH),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Bouton Google ────────────────────────────────────────────────────────────
class _GoogleBtn extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleBtn({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleLogo(),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).loginGoogle,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Écran principal ──────────────────────────────────────────────────────────
class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _switchMode() => setState(() {
        _isSignUp = !_isSignUp;
        _error = null;
      });

  void _submitEmail() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (_isSignUp) {
      notifier.signUpWithEmail(email, pass);
    } else {
      notifier.signInWithEmail(email, pass);
    }
  }

  Future<void> _forgotPassword() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.loginResetTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.loginResetBody),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l.loginEmailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.loginResetSend)),
        ],
      ),
    );
    if (send != true || !mounted) return;
    final error =
        await ref.read(authNotifierProvider.notifier).sendPasswordReset(ctrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? l.loginResetSent),
      backgroundColor: error != null
          ? Theme.of(context).colorScheme.error
          : Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading =
        authState.maybeWhen(loading: () => true, orElse: () => false);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        authenticated: (_) => context.go('/declarations'),
        loading: () {
          if (_error != null) setState(() => _error = null);
        },
        error: (msg) => setState(() => _error = msg),
      );
    });

    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // ── Bloc de marque ─────────────────────────────────────
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined,
                        color: Colors.white, size: 38),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    l.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    l.splashTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _isSignUp ? l.loginSignUpTitle : l.loginWelcome,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? l.loginSignUpSubtitle : l.loginSubtitle,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l.loginEmailLabel,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return l.loginEmailRequired;
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                      return l.loginEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: l.loginPasswordLabel,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onFieldSubmitted: (_) =>
                      (isLoading || _isSignUp) ? null : _submitEmail(),
                  validator: (v) {
                    if ((v ?? '').isEmpty) return l.loginPasswordRequired;
                    if (_isSignUp && v!.length < 6) return l.loginPasswordShort;
                    return null;
                  },
                ),
                // ── Confirmation du mot de passe (inscription uniquement) ──
                if (_isSignUp) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: l.loginConfirmPassword,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    onFieldSubmitted: (_) => isLoading ? null : _submitEmail(),
                    validator: (v) {
                      if ((v ?? '') != _passwordCtrl.text) {
                        return l.loginPasswordMismatch;
                      }
                      return null;
                    },
                  ),
                ],
                if (!_isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      child: Text(l.loginForgot),
                    ),
                  ),
                // ── Alerte d'erreur stylée (fini le texte brut) ──
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: cs.error.withValues(alpha: 0.35)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, size: 18, color: cs.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                fontSize: 13, color: cs.onSurface)),
                      ),
                    ]),
                  ),
                ],
                SizedBox(height: _isSignUp || _error != null ? 20 : 6),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitEmail,
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
                      : Text(_isSignUp ? l.loginCreateAccount : l.loginSignIn),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading ? null : _switchMode,
                  child: Text(_isSignUp ? l.loginHaveAccount : l.loginNoAccount),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l.loginOr,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),
                _GoogleBtn(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authNotifierProvider.notifier)
                          .signInWithGoogle(),
                ),
                const SizedBox(height: 28),
                Text(
                  l.loginTerms,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
