import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../declarations/providers/declarations_provider.dart';
import '../../matches/providers/matches_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final declarationsState = ref.watch(declarationsNotifierProvider);
    final matchesState = ref.watch(matchesNotifierProvider);

    final decCount =
        declarationsState.valueOrNull?.length ?? 0;
    final matchCount = matchesState.valueOrNull
        ?.where((m) => m.status == 'pending')
        .length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocRetour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.description_outlined,
                    label: 'Déclarations',
                    value: decCount.toString(),
                    color: Colors.blue,
                    onTap: () => context.push('/declarations'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                 