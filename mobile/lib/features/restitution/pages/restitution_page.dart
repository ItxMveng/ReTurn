import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restitution.dart';
import '../repositories/restitution_repository.dart';

class RestitutionPage extends ConsumerStatefulWidget {
  final String matchId;
  const RestitutionPage({super.key, required this.matchId});
  @override
  ConsumerState<RestitutionPage> createState() =>
      _RestitutionPageState();
}

class _RestitutionPageState
    extends ConsumerState<RestitutionPage> {
  Restitution? _restitution;
  bool _loading = false;
  bool _confirming = false;
  double _rating = 5;
  bool _rated = false;
  final _codeCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codeCtr.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(restitutionRepositoryProvider);
      final r = await repo.create(widget.matchId);
      setState(() => _restitution = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_codeCtr.text.trim().isEmpty) return;
    setState(() => _confirming = true);
    try {
      final repo = ref.read(restitutionRepositoryProvider);
      final r = await repo.confirm(
          _restitution!.id, _codeCtr.text.trim());
      setState(() => _restitution = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _rate() async {
    final repo = ref.read(restitutionRepositoryProvider);
    await repo.rate(_restitution!.id,
        score: _rating, isOwner: true);
    setState(() => _rated = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Restitution')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _restitution == null
              ? const Center(child: Text('Erreur lors de la création'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(children: [
                          Icon(
                            _restitution!.status == 'confirmed'
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            size: 72,
                            color: _restitution!.status == 'confirmed'
                                ? Colors.green
                                : cs.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _restitution!.status == 'confirmed'
                                ? 'Restitution confirmée !'
                                : 'En attente de confirmation',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      if (_restitution!.codeConfirmation != null &&
                          _restitution!.status != 'confirmed') ...
                        [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('Code de confirmation',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(
                                  _restitution!.codeConfirmation!,
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 8,
                                      color: cs.primary),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                    'Partagez ce code avec le propriétaire',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _codeCtr,
                            decoration: const InputDecoration(
                                labelText:
                                    'Code reçu du propriétaire'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed:
                                _confirming ? null : _confirm,
                            child: _confirming
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Text('Confirmer la restitution'),
                          ),
                        ],
                      if (_restitution!.status == 'confirmed' &&
                          !_rated) ...
                        [
                          const Text('Évaluer cette restitution',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const SizedBox(height: 12),
                          Slider(
                            value: _rating,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _rating.toStringAsFixed(0),
                            onChanged: (v) =>
                                setState(() => _rating = v),
                          ),
                          Text(
                              'Note : ${_rating.toStringAsFixed(0)} / 5',
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                              onPressed: _rate,
                              child: const Text('Envoyer l\'avis')),
                        ],
                      if (_rated)
                        const Center(
                            child: Text('Merci pour votre avis !',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green))),
                    ],
                  ),
                ),
    );
  }
}
