import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

// Coordonnées de support ReTurn.
const String kSupportEmail = 'francisitoua05@gmail.com';
const String kSupportPhone = '+330746533591'; // WhatsApp / appel

/// ── Aide & FAQ ────────────────────────────────────────────────────────────────
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoScaffold(
      title: 'Aide',
      children: [
        _Intro(
          icon: Icons.help_outline,
          text:
              'ReTurn vous aide à retrouver et restituer des documents perdus '
              'au Cameroun, en toute sécurité.',
        ),
        SizedBox(height: 8),
        _Faq(
          question: 'Comment déclarer un document ?',
          answer:
              'Depuis l’onglet Documents, appuyez sur « + », choisissez si vous '
              'avez perdu ou trouvé un document, puis scannez-le. L’IA remplit '
              'automatiquement les champs ; vérifiez-les avant de valider.',
        ),
        _Faq(
          question: 'Comment fonctionne le scan ?',
          answer:
              'Le scan utilise l’IA pour lire votre document (carte d’identité, '
              'passeport, visa, acte de naissance même manuscrit). Vos données '
              'restent confidentielles : seules les informations nécessaires au '
              'rapprochement sont conservées.',
        ),
        _Faq(
          question: 'Qu’est-ce qu’un « match » ?',
          answer:
              'Quand un document trouvé correspond à un document perdu (ou '
              'inversement), l’app crée un match. Les deux parties doivent le '
              'confirmer pour ouvrir une conversation sécurisée et organiser la '
              'restitution.',
        ),
        _Faq(
          question: 'Mes données sont-elles protégées ?',
          answer:
              'Oui. Les numéros de document et la date de naissance sont masqués '
              'côté public. Consultez la page Confidentialité pour le détail.',
        ),
      ],
    );
  }
}

/// ── Support / Contact ─────────────────────────────────────────────────────────
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoScaffold(
      title: 'Support',
      children: [
        const _Intro(
          icon: Icons.support_agent,
          text:
              'Une question, un souci avec un document ou un match ? '
              'Notre équipe vous répond.',
        ),
        const SizedBox(height: 16),
        _ContactTile(
          icon: Icons.email_outlined,
          label: 'Envoyer un email',
          value: kSupportEmail,
          onTap: () => _launch(Uri(
            scheme: 'mailto',
            path: kSupportEmail,
            query: 'subject=Support ReTurn',
          )),
        ),
        const SizedBox(height: 12),
        _ContactTile(
          icon: Icons.chat,
          label: 'WhatsApp',
          value: kSupportPhone,
          onTap: () => _launch(Uri.parse(
              'https://wa.me/${kSupportPhone.replaceAll(RegExp(r'[^0-9]'), '')}')),
        ),
        const SizedBox(height: 12),
        _ContactTile(
          icon: Icons.phone_outlined,
          label: 'Appeler',
          value: kSupportPhone,
          onTap: () => _launch(Uri(scheme: 'tel', path: kSupportPhone)),
        ),
      ],
    );
  }
}

/// ── Confidentialité ───────────────────────────────────────────────────────────
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoScaffold(
      title: 'Confidentialité',
      children: [
        _Intro(
          icon: Icons.privacy_tip_outlined,
          text:
              'Votre vie privée est au cœur de ReTurn. Voici comment nous '
              'traitons vos données.',
        ),
        SizedBox(height: 8),
        _Section(
          title: 'Données collectées',
          body:
              'Numéro de téléphone, informations de profil, et les informations '
              'des documents que vous déclarez (numéro, nom, date de naissance). '
              'Les photos servent uniquement au rapprochement et à la preuve de '
              'restitution.',
        ),
        _Section(
          title: 'Masquage des données sensibles',
          body:
              'Les numéros de document et la date de naissance ne sont jamais '
              'affichés en clair aux autres utilisateurs : ils sont partiellement '
              'masqués jusqu’à confirmation mutuelle d’un match.',
        ),
        _Section(
          title: 'Partage',
          body:
              'Vos données ne sont jamais vendues. Elles ne sont partagées avec '
              'l’autre partie d’un match qu’après confirmation, et uniquement '
              'dans la mesure nécessaire à la restitution.',
        ),
        _Section(
          title: 'Vos droits',
          body:
              'Vous pouvez modifier vos coordonnées à tout moment et demander la '
              'suppression de votre compte en contactant le support.',
        ),
      ],
    );
  }
}

// ── Briques réutilisables ──────────────────────────────────────────────────────

class _InfoScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoScaffold({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: children,
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Intro({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.onSurface, height: 1.4, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  final String question;
  final String answer;
  const _Faq({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(question,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.onSurface)),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.onSurfaceVariant,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(answer,
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        subtitle: Text(value,
            style: TextStyle(color: AppColors.onSurfaceVariant)),
        trailing:
            Icon(Icons.open_in_new, size: 18, color: AppColors.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
