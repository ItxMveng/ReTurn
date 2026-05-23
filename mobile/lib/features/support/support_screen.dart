import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/l10n/app_localizations.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    final faqs = [
      (l.supportFaq1Q, l.supportFaq1A),
      (l.supportFaq2Q, l.supportFaq2A),
      (l.supportFaq3Q, l.supportFaq3A),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l.supportTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FAQ ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel(l.supportFaqTitle),
                const SizedBox(height: 12),
                ...faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2)),
                const SizedBox(height: 28),

                // ── Contact ─────────────────────────────────────────
                _SectionLabel(l.supportContactTitle),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.email_outlined,
                                color: kGreen, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.supportContactEmail,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.supportContactDesc,
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchEmail(l.supportContactEmail),
                          icon: const Icon(Icons.send_outlined),
                          label: Text(l.supportSendEmail),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 1.2,
        ),
      );
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded ? kGreen.withValues(alpha: 0.4) : cs.outline,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.question,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _expanded ? kGreen : cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.answer,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
