import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/biometric_provider.dart';
import '../services/biometric_service.dart';

/// Verrou biométrique (F-03) — superpose un écran de déverrouillage au démarrage
/// et au retour d'arrière-plan, si l'utilisateur a activé l'option.
class BiometricLock extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricLock({super.key, required this.child});

  @override
  ConsumerState<BiometricLock> createState() => _BiometricLockState();
}

class _BiometricLockState extends ConsumerState<BiometricLock>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _busy = false;
  bool _initialChecked = false;
  bool _backgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgrounded = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_backgrounded && ref.read(biometricEnabledProvider) && !_locked) {
        _backgrounded = false;
        _lock();
      }
    }
  }

  void _lock() {
    if (!mounted) return;
    setState(() => _locked = true);
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await BiometricService.authenticate();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(biometricEnabledProvider);

    // Verrouillage initial une fois que la préférence est chargée.
    if (enabled && !_initialChecked) {
      _initialChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _lock());
    }

    return Stack(
      children: [
        widget.child,
        if (_locked) _LockScreen(busy: _busy, onUnlock: _authenticate),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool busy;
  final VoidCallback onUnlock;
  const _LockScreen({required this.busy, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Positioned.fill(
      child: Material(
        color: cs.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(Icons.lock_outline, size: 46, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text(l.appLockedTitle,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 8),
              Text(l.unlockWithBiometrics,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: busy ? null : onUnlock,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.fingerprint),
                label: Text(l.unlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
