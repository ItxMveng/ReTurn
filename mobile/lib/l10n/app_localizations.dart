// Lightweight hand-written localizations — avoids the gen-l10n build step.
// Supports: fr (default), en.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
  ];

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _strings = {
    'fr': {
      'appName': 'ReTurn',
      // Profile setup
      'profileSetupSubtitle': 'Ces informations sont nécessaires pour déclarer un document perdu.',
      'profileImportanceWarning': 'Ces informations sont officielles et obligatoires. Elles seront utilisées pour identifier le propriétaire d\'un document perdu. Veillez à renseigner des données exactes et conformes à votre pièce d\'identité.',
      'profileNameRequired': 'Nom complet requis',
      'profileNameTooShort': 'Nom trop court',
      'profileDobLabel': 'Date de naissance',
      'profileDobRequired': 'Date de naissance requise',
      'profileGenderLabel': 'Genre',
      'profileGenderMale': 'Homme',
      'profileGenderFemale': 'Femme',
      'profileGenderOther': 'Autre',
      'profileGenderRequired': 'Genre requis',
      'profileNationalIdLabel': 'Numéro CNI / Passeport (optionnel)',
      'profileNationalIdHelper': 'Numéro figurant sur votre pièce d\'identité officielle',
      'profileNationalIdRequired': 'Numéro de pièce requis',
      'profileCityLabel': 'Ville / Lieu de naissance',
      'profileCityRequired': 'Lieu de naissance requis',
      'profileRegionLabel': 'Région (optionnel)',
      'profileAddressLabel': 'Adresse actuelle (optionnel)',
      'profileAddressRequired': 'Adresse requise',
      // Profile incomplete gate
      'profileIncompleteTitle': 'Profil incomplet',
      'profileIncompleteDesc': 'Vous devez compléter votre profil avant de déclarer un document perdu. Ces informations permettent d\'identifier le propriétaire lors de la restitution.',
      'profileCompleteNow': 'Compléter mon profil',
      // Support
      'supportTitle': 'Support & Aide',
      'supportFaqTitle': 'Questions fréquentes',
      'supportFaq1Q': 'Comment fonctionne ReTurn ?',
      'supportFaq1A': 'ReTurn met en relation les personnes ayant trouvé un document avec celles qui l\'ont perdu. Notre algorithme compare les déclarations et génère des correspondances automatiques.',
      'supportFaq2Q': 'Mes données sont-elles sécurisées ?',
      'supportFaq2A': 'Oui. Vos informations personnelles ne sont visibles que lors d\'un match confirmé, et uniquement par la contrepartie directement impliquée.',
      'supportFaq3Q': 'Que faire si je ne trouve pas mon document ?',
      'supportFaq3A': 'Laissez votre déclaration active. Vous recevrez une notification dès qu\'un document correspondant est déclaré trouvé.',
      'supportContactTitle': 'Nous contacter',
      'supportContactEmail': 'support@return-app.cm',
      'supportContactDesc': 'Envoyez-nous un e-mail pour toute question ou problème.',
      'supportSendEmail': 'Envoyer un e-mail',
      // Guided tour
      'tourSkip': 'Passer',
      'tourNext': 'Suivant',
      'tourDone': 'C\'est parti !',
      'tourStep1Title': 'Bienvenue sur ReTurn !',
      'tourStep1Body': 'Voici un rapide tour des fonctionnalités essentielles. Cela ne prendra qu\'une minute.',
      'tourStep2Title': 'Documents',
      'tourStep2Body': 'Déclarez un document trouvé (photo + lecture OCR automatique) ou un document perdu. Retrouvez et gérez toutes vos déclarations actives ici.',
      'tourStep3Title': 'Matchs automatiques',
      'tourStep3Body': 'Notre algorithme compare les déclarations en temps réel. Dès qu\'un match est détecté, vous êtes notifié ici pour le confirmer.',
      'tourStep4Title': 'Messages & Restitution',
      'tourStep4Body': 'Échangez en sécurité avec l\'autre partie, vérifiez votre identité et coordonnez ensemble la remise du document.',
      'tourStep5Title': 'Profil & Réputation',
      'tourStep5Body': 'Consultez votre score de confiance, vos statistiques de restitutions réussies et gérez vos paramètres personnels.',
      'settingsTitle': 'Paramètres',
      'settingsTheme': 'Apparence',
      'settingsThemeLight': 'Clair',
      'settingsThemeDark': 'Sombre',
      'settingsThemeNightBlue': 'Nuit bleue',
      'settingsLanguage': 'Langue',
      'settingsLanguageSystem': 'Langue du système',
      'settingsLanguageFr': 'Français',
      'settingsLanguageEn': 'English',
      'settingsAbout': 'À propos',
      'settingsVersion': 'Version',
      'settingsLogout': 'Se déconnecter',
      'homeGreeting': 'Bonjour 👋',
      'homeQuestion': 'Que souhaitez-vous faire ?',
      'homeFoundDoc': "J'ai trouvé un document",
      'homeFoundDocSub': 'Photographiez et déclarez un document trouvé',
      'homeLostDoc': "J'ai perdu un document",
      'homeLostDocSub': 'Déclarez la perte pour être notifié',
      'homeDeclarations': 'Mes déclarations',
      'homeDeclarationsSub': 'Consulter et gérer vos déclarations',
      'homeMatches': 'Mes matches',
      'homeMatchesSub': 'Documents trouvés correspondant à vos pertes',
      'onboardingSkip': 'Passer',
      'onboardingNext': 'Suivant',
      'onboardingStart': 'Commencer',
      'onboarding1Title': 'Déclarez un document trouvé',
      'onboarding1Body': 'Photographiez le document et signalez-le en quelques secondes.',
      'onboarding2Title': 'Retrouvez vos documents',
      'onboarding2Body': "Déclarez un document perdu et soyez notifié dès qu'il est retrouvé.",
      'onboarding3Title': 'Restitution sécurisée',
      'onboarding3Body': 'Un processus vérifié protège les deux parties lors de la remise.',
      'phoneInputTitle': 'Connexion',
      'phoneInputSubtitle': 'Entrez votre numéro pour recevoir un code.',
      'phoneInputLabel': 'Numéro de téléphone',
      'phoneInputReceive': 'Recevoir le code',
      'phoneInputOr': 'ou',
      'phoneInputGoogle': 'Continuer avec Google',
      'phoneInputTerms': "En continuant, vous acceptez nos Conditions d'utilisation.",
      'phoneValidRequired': 'Numéro requis',
      'phoneValidLength': '9 chiffres requis',
      'otpTitle': 'Code de vérification',
      'otpSentTo': 'Code envoyé au',
      'otpResendIn': 'Renvoyer dans',
      'otpResend': 'Renvoyer le code',
      'otpVerify': 'Vérifier',
      'splashTagline': 'Retrouver. Restituer. Confiance.',
      'matchesTitle': 'Mes matches',
      'matchesEmpty': "Aucun match pour l'instant",
      'matchesEmptyDesc': "Les matches apparaissent automatiquement lorsqu'un document trouvé correspond à un document perdu.",
      'matchFound': 'Trouvé',
      'matchLost': 'Perdu',
      'matchIgnore': 'Ignorer',
      'matchConfirm': 'Confirmer',
      'matchOpenChat': 'Ouvrir le chat',
      'matchVerifyId': 'Vérifier mon identité',
      'matchConfirmThis': 'Confirmer ce match',
      'chatConnected': 'Connecté',
      'chatDisconnected': 'Déconnecté',
      'chatPlaceholder': 'Votre message…',
      'chatSendLocation': 'Envoyer une zone de récupération',
      'verifyTitle': "Vérification d'identité",
      'verifyDesc': 'Pour sécuriser la restitution, chaque participant doit soumettre un selfie tenant son document d\'identité.',
      'verifyStart': 'Démarrer la vérification',
      'verifyTakeSelfie': 'Prendre le selfie',
      'verifySubmit': 'Soumettre',
      'verifyApproved': 'Identité vérifiée. Vous pouvez procéder à la restitution.',
      'declarationsTitle': 'Mes déclarations',
      'declarationsEmpty': "Aucune déclaration pour l'instant",
      'declarationsEmptyDesc': 'Utilisez les boutons ci-dessous pour déclarer un document trouvé ou perdu.',
      'declarationFoundTitle': 'Document trouvé',
      'declarationLostTitle': 'Document perdu',
      'profileTitle': 'Votre profil',
      'profileWelcome': 'Bienvenue sur ReTurn !',
      'profileNameLabel': 'Nom complet',
      'profileContinue': 'Continuer',
      'errorGeneric': 'Une erreur est survenue. Réessayez.',
      'errorNetwork': 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'confirmDelete': 'Supprimer ?',
      'confirmDeleteDesc': 'Cette déclaration sera définitivement supprimée.',
      'selfieRequired': 'Selfie requis',
      // Navigation
      'navDocuments': 'Documents',
      'navMatches': 'Matchs',
      'navMessages': 'Messages',
      'navProfile': 'Profil',
      // Accueil / déclarations
      'greetingHello': 'Bonjour',
      'greetingMorning': 'Bonjour',
      'greetingAfternoon': 'Bon après-midi',
      'greetingEvening': 'Bonsoir',
      // Connexion
      'loginWelcome': 'Bienvenue sur ReTurn',
      'loginSubtitle':
          'Connectez-vous par email ou avec votre compte Google.',
      'loginOr': 'ou',
      'loginGoogle': 'Continuer avec Google',
      'loginEmailLabel': 'Adresse email',
      'loginPasswordLabel': 'Mot de passe',
      'loginSignIn': 'Se connecter',
      'loginCreateAccount': 'Créer un compte',
      'loginNoAccount': 'Pas encore de compte ? Créer un compte',
      'loginHaveAccount': 'Déjà un compte ? Se connecter',
      'loginForgot': 'Mot de passe oublié ?',
      'loginEmailRequired': 'Email requis',
      'loginEmailInvalid': 'Adresse email invalide',
      'loginPasswordRequired': 'Mot de passe requis',
      'loginPasswordShort': 'Au moins 6 caractères',
      'loginResetTitle': 'Réinitialiser le mot de passe',
      'loginResetBody':
          'Entrez votre email, nous vous enverrons un lien de réinitialisation.',
      'loginResetSend': 'Envoyer le lien',
      'loginResetSent':
          'Email de réinitialisation envoyé. Vérifiez votre boîte mail.',
      'loginSignUpTitle': 'Créer votre compte',
      'loginSignUpSubtitle': 'Rejoignez ReTurn en quelques secondes.',
      'loginConfirmPassword': 'Confirmer le mot de passe',
      'loginPasswordMismatch': 'Les mots de passe ne correspondent pas',
      'loginTerms': 'En continuant, vous acceptez nos conditions '
          'd\'utilisation et notre politique de confidentialité (CPDP).',
      // Statut de déclaration
      'declStatusActive': 'Active',
      'declStatusMatched': 'Matchée',
      'declStatusReturned': 'Restituée',
      'declStatusCancelled': 'Annulée',
      'homeHeroTitle': 'Un document entre vos mains ?',
      'homeHeroSubtitle': 'Déclarez-le, on s\'occupe du rapprochement.',
      'homeFound': 'J\'ai trouvé',
      'homeLost': 'J\'ai perdu',
      'declMine': 'Mes déclarations',
      'declNew': 'Nouvelle',
      'declActive': 'actives',
      'declLimitReached': 'Clôturez une déclaration pour en créer une nouvelle',
      'statActive': 'Actives',
      'statMatched': 'Matchées',
      'statRestituted': 'Restituées',
      'declEmptyTitle': 'Vous n\'avez aucune déclaration',
      'declEmptySubtitle': 'Vous avez perdu un document ?\nSignalez-le en 60 secondes.',
      'declEmptyCta': 'Déclarer un document perdu',
      'declChooseTitle': 'Que voulez-vous déclarer ?',
      'declChooseFound': 'J\'ai trouvé un document',
      'declChooseFoundSub': 'Aidez à le rendre à son propriétaire',
      'declChooseLost': 'J\'ai perdu un document',
      'declChooseLostSub': 'Soyez alerté dès qu\'il est retrouvé',
      'profileCompleteBanner': 'Complétez votre profil',
      'profileCompleteBannerSub': 'Nom, photo et adresse — nécessaires pour la restitution.',
      'retry': 'Réessayer',
      // Notifications
      'notifTitle': 'Notifications',
      'notifClearAll': 'Tout effacer',
      'notifLoadError': 'Impossible de charger les notifications',
      'notifEmpty': 'Aucune notification',
      'notifEmptySub': 'Vous serez alerté dès qu\'un document\ncorrespondant est trouvé.',
      'notifMatchFound': 'Document correspondant trouvé !',
      'notifGeneric': 'Notification',
      'notifCorrespondence': '% de correspondance',
      // Formulaire de déclaration (S-08/S-09)
      'declFormTitle': 'Nouvelle déclaration',
      'declTagFound': 'Trouvé',
      'declTagLost': 'Perdu',
      'declScanStep': 'Étape 1 — Scanner pour pré-remplir (IA)',
      'declScanned': 'Document scanné ✓',
      'declScanHint': 'Les informations sont lues automatiquement.',
      'declScanRedo': 'Appuyez pour recommencer le scan.',
      'declOwnLostTitle': 'Vous déclarez votre propre document',
      'declOwnerLabel': 'Nom du propriétaire (sur le document)',
      'declOwnerHint': 'Ex : ITOUA Francis',
      'declFieldRequired': 'Champ requis',
      'declWhichFound': 'Quel document avez-vous trouvé ?',
      'declWhichLost': 'Quel document avez-vous perdu ?',
      'declDossier': 'Documents du dossier',
      'declAddOther': 'Ajouter un autre document de cette personne',
      'declAddMore': 'Ajouter un document',
      'declSamePerson': 'Ces documents appartiennent à la même personne et forment un seul dossier.',
      'declDocNumber': 'Numéro du document (facultatif)',
      'declDocNumberHint': 'Renforce la précision du rapprochement',
      'declWhereWhenFound': 'Où et quand l\'avez-vous trouvé ?',
      'declWhereWhenLost': 'Où et quand l\'avez-vous perdu ?',
      'declPlaceFound': 'Lieu de la découverte',
      'declPlaceLost': 'Ville / quartier de la perte',
      'declMyPosition': 'Ma position',
      'declPositionAdded': 'Position ajoutée',
      'declDate': 'Date',
      'declPhotosOptional': 'Photos (facultatif)',
      'declDescOptional': 'Description (facultatif)',
      'declSubmitFound': 'Déclarer le document trouvé',
      'declSubmitLost': 'Déclarer la perte',
      'declSubmitDossier': 'Déclarer le dossier',
      'declNoteFound': 'Les données sensibles seront masquées automatiquement.',
      'declNoteLost': 'Vous serez alerté dès qu\'un document correspond.',
      'declSavedFound': 'Document trouvé déclaré.',
      'declSavedLost': 'Perte déclarée.',
      'declSaveError': 'Enregistrement impossible. Vérifiez votre connexion et réessayez.',
      'declTakePhoto': 'Prendre une photo',
      'declFromGallery': 'Choisir dans la galerie',
      // Matchs (liste)
      'matchesTitle2': 'Mes correspondances',
      'matchFilterAll': 'Tous',
      'matchFilterPending': 'En attente',
      'matchFilterConfirmed': 'Confirmés',
      'matchesSearching': 'Nous cherchons continuellement\npour vous.',
      'matchDeclareDoc': 'Déclarer un document',
      'matchStatusAwaitYou': 'En attente de votre confirmation',
      'matchStatusAwaitOther': 'En attente de l\'autre partie',
      'matchStatusConfirmedVerify': 'Confirmé — Vérifiez votre identité',
      'matchStatusVerifiedChat': 'Vérifié — Discutez',
      'matchStatusAwaitOwner': 'En attente du propriétaire',
      'matchStatusIgnored': 'Ignoré',
      'matchStatusClosed': 'Clôturé',
      // Chat
      'chatTitle': 'Conversation',
      'chatSecureHandover': 'Restitution sécurisée',
      'chatOrganizeReturn': 'Organiser la restitution',
      'chatSafetyBanner': 'Ne partagez pas d\'informations sensibles. Convenez d\'un lieu public ou certifié pour la restitution.',
      'chatLoadError': 'Impossible de charger la conversation',
      'chatStart': 'Démarrez la conversation',
      'chatClosed': 'La conversation est fermée',
      'chatPhoneWarning': 'Évitez de partager votre numéro : la remise se fait en lieu public via l\'application.',
      'chatLocationShared': 'Position partagée',
      'chatSendFailed': 'Échec de l\'envoi, réessayez.',
      'chatMessageHint': 'Votre message…',
      'chatDateToday': 'Aujourd\'hui',
      'chatDateYesterday': 'Hier',
      // Signalement
      'reportUser': 'Signaler cet utilisateur',
      'reportReason': 'Motif',
      'reportDetails': 'Détails (optionnel)',
      'reportSend': 'Envoyer',
      'reportSent': 'Signalement envoyé. Merci.',
      'reportFailed': 'Échec du signalement.',
      'reasonFraud': 'Tentative d\'escroquerie',
      'reasonHarassment': 'Harcèlement / insultes',
      'reasonFakeDoc': 'Document falsifié',
      'reasonIdentityTheft': 'Usurpation d\'identité',
      'reasonInappropriate': 'Contenu inapproprié',
      'reasonOther': 'Autre',
      // Types de documents
      'docCni': 'Carte Nationale d\'Identité',
      'docPassport': 'Passeport',
      'docDrivingLicense': 'Permis de conduire',
      'docVehicleReg': 'Carte grise',
      'docBirthCert': 'Acte de naissance',
      'docStudentCard': 'Carte étudiante',
      'docBankCard': 'Carte bancaire',
      'docDiploma': 'Diplôme',
      'docOther': 'Autre document',
      'declRemoveDoc': 'Retirer ce document',
      'commonUser': 'Utilisateur',
      // Détail de la correspondance
      'mdTitle': 'Correspondance',
      'mdLoadError': 'Impossible de charger la correspondance',
      'mdScoreStrong': 'Correspondance forte',
      'mdScoreProbable': 'Correspondance probable',
      'mdScoreWeak': 'Correspondance faible',
      'mdConfidence': 'confiance',
      'mdScoreExplain': 'Score basé sur : le nom sur le document (fort), '
          'le numéro du document (fort), la localisation (moyen) '
          'et la cohérence des dates.',
      'mdFieldDocument': 'Document',
      'mdFieldNameOnDoc': 'Nom sur le document',
      'mdFieldLocation': 'Lieu',
      'mdFieldStatus': 'Statut',
      'mdFieldDetectedOn': 'Détecté le',
      'mdStatusPending': 'En attente de vérification',
      'mdStatusVerified': 'Identité vérifiée',
      'mdStatusConfirmed': 'Confirmé',
      'mdStatusIgnored': 'Ignoré',
      'mdStatusClosed': 'Clôturé',
      'mdOwnerVerified': 'Identité vérifiée ✓ — vous pouvez discuter avec '
          '{name} pour organiser la récupération.',
      'mdOpenConversation': 'Ouvrir la conversation',
      'mdOwnerInReview': 'Votre dossier de vérification est en cours de '
          'validation par notre équipe (sous 24 h). Vous serez notifié.',
      'mdOwnerRejectedReason': 'Vérification refusée : {reason}. '
          'Vous pouvez réessayer.',
      'mdOwnerRejected': 'Vérification refusée. Vous pouvez réessayer.',
      'mdRetryVerification': 'Réessayer la vérification',
      'mdOwnerPrompt': 'Ce document semble être le vôtre. Vérifiez votre '
          'identité pour débloquer la conversation avec la personne '
          'qui l\'a trouvé.',
      'mdVerifyMyIdentity': 'Vérifier mon identité',
      'mdNotMyDocument': 'Ce n\'est pas mon document',
      'mdFinderVerified': '{name} a vérifié son identité ✓ — vous pouvez '
          'discuter pour organiser la remise du document.',
      'mdFinderWaiting': 'Un propriétaire potentiel a été trouvé. En attente '
          'de la vérification de son identité — vous serez notifié dès '
          'qu\'elle est faite.',
      'mdDocPhotos': 'Photos du document',
      'mdProtectedData': 'Données protégées',
      'mdStepDiscovered': 'Découvert',
      'mdStepVerified': 'Vérifié',
      'mdStepReturned': 'Restitué',
      // Vérification d'identité
      'verifTitle': 'Vérification d\'identité',
      'verifDobHelp': 'Votre date de naissance',
      'verifValidate': 'Valider',
      'verifErrName': 'Veuillez saisir votre nom complet.',
      'verifErrDob': 'Veuillez indiquer votre date de naissance.',
      'verifErrDocNum':
          'Le numéro du document est requis pour cette vérification.',
      'verifErrMismatch': 'Les informations ne correspondent pas. Réessayez.',
      'verifErrGeneric': 'Une erreur est survenue. Réessayez.',
      'verifErrSelfie': 'Envoi du selfie impossible. Réessayez.',
      'verifErrDocPhoto': 'Envoi de la photo impossible. Réessayez.',
      'verifIntroTitle': 'Confirmons que ce document est bien le vôtre',
      'verifIntroBody': 'Cette étape sert uniquement à nous assurer que vous '
          'êtes réellement le titulaire du document, afin d\'éviter les '
          'usurpations d\'identité et les fraudes. Personne d\'autre n\'y a accès.',
      'verifStart': 'Commencer la vérification',
      'verifL1B1': 'Vérification rapide : votre nom et votre date de '
          'naissance suffisent.',
      'verifBulletConfidential':
          'Vos réponses sont confidentielles et ne sont jamais partagées.',
      'verifBulletProtect':
          'C\'est ce qui protège chaque propriétaire sur ReTurn.',
      'verifL2B1': 'Deux étapes rapides : quelques infos du document, puis '
          'un selfie.',
      'verifL2B2': 'Vos réponses et votre selfie restent privés.',
      'verifL3B1': 'Trois étapes : infos du document, un selfie, puis une '
          'photo du document.',
      'verifL3B2': 'Notre équipe valide votre dossier sous 24 h pour une '
          'sécurité maximale.',
      'verifL3B3': 'Toutes vos données restent privées et protégées.',
      'verifQTitle': 'Questions de contrôle',
      'verifQSubtitle3': 'Renseignez votre nom tel qu\'il figure sur le '
          'document, votre date de naissance et le numéro du document.',
      'verifQSubtitle': 'Renseignez votre nom tel qu\'il figure sur le '
          'document et votre date de naissance.',
      'verifFieldName': 'Nom complet sur le document',
      'verifFieldDob': 'Date de naissance',
      'verifDobSelect': 'Sélectionner…',
      'verifFieldDocNum': 'Numéro du document',
      'verifFieldDocNumHelper': 'Requis pour cette vérification renforcée.',
      'verifSubmit': 'Vérifier',
      'verifSelfieTitle': 'Un dernier pas : votre selfie',
      'verifSelfieBody': 'Bonnes réponses ✓. Prenez un selfie pour confirmer '
          'que c\'est bien vous. Cette photo sert uniquement à la vérification '
          'et reste privée.',
      'verifSelfieBtn': 'Prendre un selfie',
      'verifDocTitle': 'Photo d\'un justificatif',
      'verifDocBody': 'Photographiez une pièce prouvant votre identité '
          '(ancienne CNI, récépissé, acte de naissance…). Notre équipe '
          'l\'examine sous 24 h — elle n\'est jamais partagée avec l\'autre partie.',
      'verifDocBtn': 'Photographier le justificatif',
      'verifReviewTitle': 'Dossier en cours de validation',
      'verifReviewBody': 'Merci ! Votre dossier est complet. Notre équipe le '
          'vérifie sous 24 h — vous recevrez une notification dès que c\'est validé.',
      'verifUnderstood': 'Compris',
      'verifRejectedTitle': 'Vérification non validée',
      'verifRejectedReason': 'Motif : {reason}',
      'verifRejectedBody': 'Les éléments fournis n\'ont pas permis de '
          'confirmer votre identité.',
      'verifClose': 'Fermer',
      'verifDoneTitle': 'Identité vérifiée',
      'verifDoneBody': 'Merci ! Vous pouvez maintenant organiser la '
          'restitution en toute confiance.',
      'verifDoneRestitution': 'Organiser la restitution',
      'verifDoneLater': 'Plus tard',
      // Restitution
      'restTitle': 'Restitution',
      'restLoadError': 'Impossible de charger la restitution.',
      'restProofTitle': 'Photo de preuve requise',
      'restProofBody': 'Prenez une photo du document au moment de la remise. '
          'Elle protège les deux parties en cas de litige.',
      'restTakePhoto': 'Prendre la photo',
      'restActionFail': 'Action impossible, réessayez.',
      'restMeetingSaveFail': 'Impossible d\'enregistrer le lieu.',
      'restPosUnavailable': 'Position indisponible — vérifiez la localisation.',
      'restZonesLoadFail': 'Chargement des lieux impossible. Réessayez.',
      'restNoZones': 'Aucun lieu public référencé pour le moment.',
      'restRateThanks': 'Merci pour votre évaluation !',
      'restRateFail': 'Évaluation impossible (déjà notée ?).',
      'restMeetNearby': 'Suggérer un lieu public à proximité',
      'restMeetNearbySub': 'Utilise votre position GPS',
      'restMeetZone': 'Choisir une zone certifiée',
      'restMeetZoneSub': 'Commissariat, mairie, campus — recommandé',
      'restMeetManual': 'Saisir un autre lieu',
      'restNearbyTitle': 'Lieux publics à proximité',
      'restMeetDialogTitle': 'Lieu de rendez-vous',
      'restMeetHint': 'Ex : Commissariat de Bonanjo',
      'restMeetHelper': 'Privilégiez un lieu public ou certifié.',
      'restSave': 'Enregistrer',
      'restNotReadyTitle': 'Restitution pas encore ouverte',
      'restNotReadyBody': 'Les deux parties doivent d\'abord confirmer le '
          'match. La restitution s\'ouvrira automatiquement ensuite.',
      'restDoneStatus': 'Document récupéré ! 🎉 Merci d\'avoir utilisé ReTurn.',
      'restIConfirmedWaiting': 'Vous avez confirmé ✓ — en attente de la '
          'confirmation de l\'autre partie.',
      'restStep1Of3': 'Étape 1/3 — Convenez d\'un lieu public pour la remise.',
      'restStep2Of3': 'Étape 2/3 — Confirmez une fois le document remis en '
          'main propre.',
      'restMeetingUnset': 'Non défini — convenez d\'un lieu public ou certifié.',
      'restEdit': 'Modifier',
      'restChoose': 'Choisir',
      'restHandoffTitle': 'Confirmation de la remise',
      'restRoleOwner': 'Propriétaire',
      'restRoleFinder': 'Découvreur',
      'restConfirmed': 'confirmé ✓',
      'restPending': 'en attente',
      'restProofCardTitle': 'Photo de preuve',
      'restProofCardSub': '{count} photo(s) enregistrée(s) — protège les '
          'deux parties.',
      'restChooseMeetingBtn': 'Choisir le lieu de rendez-vous',
      'restNextStepHint': 'Étape suivante : confirmer la remise une fois le '
          'document échangé en main propre.',
      'restIGotDoc': 'J\'ai récupéré mon document',
      'restIGaveDoc': 'J\'ai remis le document',
      'restWaitingOther': 'En attente de la confirmation de l\'autre partie. '
          'Vous serez notifié dès qu\'elle sera faite.',
      'restRatedTitle': 'Évaluation envoyée',
      'restRatedSub': 'Merci ! Votre note aide la communauté ReTurn.',
      'restRateQuestion': 'Comment s\'est passée la remise avec {name} ?',
      'restOtherParty': 'l\'autre partie',
      'restStepRdv': 'RDV',
      'restStepHandover': 'Remise',
      'restStepRating': 'Évaluation',
      'restCommentLabel': 'Commentaire (optionnel)',
      'restSendRating': 'Envoyer mon évaluation',
      'restConfettiTitle': 'Document récupéré !',
      'restReputation': 'Réputation : {value}/10',
      // Profil
      'profTitle': 'Profil',
      'profLoading': 'Chargement du profil…',
      'profErrorTitle': 'Impossible de charger le profil',
      'profLogout': 'Se déconnecter',
      'profFieldName': 'Nom complet',
      'profFieldContact': 'Téléphone ou email',
      'profFieldDob': 'Date de naissance',
      'profFieldGender': 'Genre',
      'profFieldCity': 'Ville',
      'profFieldIdNum': 'Numéro CNI / Passeport',
      'profCompleteTitle': 'Complétez votre profil en 1 minute',
      'profCompleteBody': 'Ces informations servent à vérifier votre identité '
          'lors de la récupération d\'un document.',
      'profCompleteNow': 'Compléter maintenant',
      'profDeleteTitle': 'Supprimer mon compte',
      'profDeleteBody': 'Cette action est définitive et irréversible. Votre '
          'compte, vos déclarations, vos matchs et vos messages seront '
          'supprimés conformément à votre droit à l\'effacement (RGPD/CPDP).'
          '\n\nVoulez-vous vraiment continuer ?',
      'profDeleteConfirm': 'Supprimer définitivement',
      'profDeleteFailed': 'Suppression impossible, réessayez.',
      'profSectionMyProfile': 'Mon profil',
      'profSectionAppearance': 'Apparence',
      'profSectionLanguage': 'Langue',
      'profSectionSecurity': 'Sécurité',
      'profSectionHelp': 'Aide & support',
      'profSectionAbout': 'À propos',
      'profSectionDanger': 'Zone de danger',
      'profEditProfile': 'Modifier / compléter mon profil',
      'profMyReturns': 'Mes restitutions',
      'profZones': 'Zones de récupération',
      'profThemeLight': 'Clair',
      'profThemeDark': 'Sombre',
      'profLangSystem': 'Langue du système',
      'profHelpFaq': 'Aide & FAQ',
      'profContactSupport': 'Contacter le support',
      'profPrivacy': 'Confidentialité',
      'profVersion': 'Version',
      'profDeleteAccount': 'Supprimer mon compte (RGPD)',
      'profFieldsFilled': '{filled}/{total} champs renseignés',
      'profEditSubtitle': 'Complétez vos informations. La photo se change '
          'depuis l\'avatar.',
      'profNameInputLabel': 'Nom complet (nom et prénom)',
      'profNameInputHelper': 'Non modifiable une fois enregistré.',
      'profPhoneLabel': 'Numéro de téléphone',
      'profAddPhoneLabel': 'Ajouter un numéro (+237…)',
      'profAddPhoneHelper': 'Pour vous connecter aussi par SMS.',
      'profEmailLabel': 'Email',
      'profAddEmailLabel': 'Ajouter un email',
      'profAddEmailHelper': 'Pour vous connecter aussi via Google.',
      'profDobHelper': 'Utilisée pour vérifier votre identité.',
      'profGenderMale': 'Homme',
      'profGenderFemale': 'Femme',
      'profGenderOther': 'Autre',
      'profAddressLabel': 'Adresse actuelle',
      'profIdHelper': 'Optionnel — accélère la vérification.',
      'profUpdated': 'Profil mis à jour',
      'profSavePartialError': 'Vos informations ont été enregistrées ✓ — '
          'mais : {err} Effacez ce champ ou utilisez une autre coordonnée.',
      'profReadOnlyHelper': 'Vérification requise pour modifier.',
      'profAvatarUpdated': 'Photo mise à jour',
      'profAvatarCancelled': 'Annulé',
      'profBadgeComplete': 'Complet',
      'profBadgeIncomplete': 'Incomplet',
      'profBiometricTitle': 'Déverrouillage biométrique',
      'profBiometricSub': 'Empreinte ou visage à l\'ouverture',
      'profBiometricNone': 'Aucune biométrie configurée sur cet appareil.',
      'profBiometricReason': 'Activez le verrouillage biométrique',
      'profChangePhoto': 'Changer la photo de profil',
      'errorTitle': 'Oups, un souci',
      // Déclaration multi-documents (tri automatique)
      'mdocTitle': 'Déclarer plusieurs documents',
      'mdocIntro': 'Ajoutez ou photographiez tous les documents. L\'app lit '
          'chaque fichier et regroupe automatiquement les documents par '
          'personne — un dossier par propriétaire.',
      'mdocAddGallery': 'Ajouter depuis la galerie',
      'mdocTakePhotos': 'Prendre une photo',
      'mdocAnalyzing': 'Analyse des documents…',
      'mdocDossierOwner': 'Propriétaire du dossier',
      'mdocOwnerHint': 'Nom sur les documents',
      'mdocNoName': 'Sans nom détecté',
      'mdocRemove': 'Retirer',
      'mdocAddMore': 'Ajouter d\'autres documents',
      'mdocLocation': 'Lieu (optionnel, améliore le rapprochement)',
      'mdocEmpty': 'Aucun document ajouté pour l\'instant.',
      'mdocDetected': '{n} personne(s) détectée(s)',
      'mdocSubmit': 'Déclarer {n} dossier(s)',
      'mdocSuccess': '{n} dossier(s) déclaré(s) ✓',
      'mdocError': 'Enregistrement impossible. Réessayez.',
      'mdocOwnerRequired': 'Indiquez le nom du propriétaire pour chaque dossier.',
      'mdocChooseSub': 'Portefeuille, plusieurs personnes — tri automatique',
      'dossierBadge': 'DOSSIER',
      'dossierDocsCount': '{n} documents',
      'dossierTitle': 'Dossier',
      'dossierEmpty': 'Ce dossier est vide.',
    },
    'en': {
      'appName': 'ReTurn',
      // Profile setup
      'profileSetupSubtitle': 'This information is required to declare a lost document.',
      'profileImportanceWarning': 'This information is official and mandatory. It will be used to identify the owner of a lost document. Please enter accurate data that matches your official ID document.',
      'profileNameRequired': 'Full name is required',
      'profileNameTooShort': 'Name is too short',
      'profileDobLabel': 'Date of birth',
      'profileDobRequired': 'Date of birth is required',
      'profileGenderLabel': 'Gender',
      'profileGenderMale': 'Male',
      'profileGenderFemale': 'Female',
      'profileGenderOther': 'Other',
      'profileGenderRequired': 'Gender is required',
      'profileNationalIdLabel': 'National ID / Passport number (optional)',
      'profileNationalIdHelper': 'Number shown on your official identity document',
      'profileNationalIdRequired': 'ID number is required',
      'profileCityLabel': 'City / Place of birth',
      'profileCityRequired': 'Place of birth is required',
      'profileRegionLabel': 'Region (optional)',
      'profileAddressLabel': 'Current address (optional)',
      'profileAddressRequired': 'Address is required',
      // Profile incomplete gate
      'profileIncompleteTitle': 'Incomplete profile',
      'profileIncompleteDesc': 'You must complete your profile before declaring a lost document. This information is used to identify the owner during handover.',
      'profileCompleteNow': 'Complete my profile',
      // Support
      'supportTitle': 'Support & Help',
      'supportFaqTitle': 'Frequently asked questions',
      'supportFaq1Q': 'How does ReTurn work?',
      'supportFaq1A': 'ReTurn connects people who found a document with those who lost it. Our algorithm compares declarations and generates automatic matches.',
      'supportFaq2Q': 'Is my data secure?',
      'supportFaq2A': 'Yes. Your personal information is only visible during a confirmed match, and only to the directly involved counterpart.',
      'supportFaq3Q': 'What if I can\'t find my document?',
      'supportFaq3A': 'Keep your declaration active. You will receive a notification as soon as a matching found document is declared.',
      'supportContactTitle': 'Contact us',
      'supportContactEmail': 'support@return-app.cm',
      'supportContactDesc': 'Send us an email for any question or issue.',
      'supportSendEmail': 'Send an email',
      // Guided tour
      'tourSkip': 'Skip',
      'tourNext': 'Next',
      'tourDone': 'Let\'s go!',
      'tourStep1Title': 'Welcome to ReTurn!',
      'tourStep1Body': 'Here is a quick tour of the key features. It will only take a minute.',
      'tourStep2Title': 'Documents',
      'tourStep2Body': 'Declare a found document (photo + automatic OCR) or a lost document. View and manage all your active declarations here.',
      'tourStep3Title': 'Automatic Matches',
      'tourStep3Body': 'Our algorithm compares declarations in real time. When a match is detected, you are notified here to confirm it.',
      'tourStep4Title': 'Messages & Handover',
      'tourStep4Body': 'Communicate securely with the other party, verify your identity, and coordinate the document handover together.',
      'tourStep5Title': 'Profile & Reputation',
      'tourStep5Body': 'View your trust score, successful handover statistics, and manage your personal settings.',
      'settingsTitle': 'Settings',
      'settingsTheme': 'Appearance',
      'settingsThemeLight': 'Light',
      'settingsThemeDark': 'Dark',
      'settingsThemeNightBlue': 'Night blue',
      'settingsLanguage': 'Language',
      'settingsLanguageSystem': 'System language',
      'settingsLanguageFr': 'Français',
      'settingsLanguageEn': 'English',
      'settingsAbout': 'About',
      'settingsVersion': 'Version',
      'settingsLogout': 'Log out',
      'homeGreeting': 'Hello 👋',
      'homeQuestion': 'What would you like to do?',
      'homeFoundDoc': 'I found a document',
      'homeFoundDocSub': 'Photograph and declare a found document',
      'homeLostDoc': 'I lost a document',
      'homeLostDocSub': 'Report the loss to be notified',
      'homeDeclarations': 'My declarations',
      'homeDeclarationsSub': 'View and manage your declarations',
      'homeMatches': 'My matches',
      'homeMatchesSub': 'Found documents matching your losses',
      'onboardingSkip': 'Skip',
      'onboardingNext': 'Next',
      'onboardingStart': 'Get started',
      'onboarding1Title': 'Declare a found document',
      'onboarding1Body': 'Photograph the document and report it in seconds.',
      'onboarding2Title': 'Find your documents',
      'onboarding2Body': 'Report a lost document and be notified as soon as it is found.',
      'onboarding3Title': 'Secure restitution',
      'onboarding3Body': 'A verified process protects both parties during handover.',
      'phoneInputTitle': 'Sign in',
      'phoneInputSubtitle': 'Enter your number to receive a verification code.',
      'phoneInputLabel': 'Phone number',
      'phoneInputReceive': 'Receive code',
      'phoneInputOr': 'or',
      'phoneInputGoogle': 'Continue with Google',
      'phoneInputTerms': 'By continuing, you agree to our Terms of Use.',
      'phoneValidRequired': 'Number required',
      'phoneValidLength': '9 digits required',
      'otpTitle': 'Verification code',
      'otpSentTo': 'Code sent to',
      'otpResendIn': 'Resend in',
      'otpResend': 'Resend code',
      'otpVerify': 'Verify',
      'splashTagline': 'Find. Return. Trust.',
      'matchesTitle': 'My matches',
      'matchesEmpty': 'No matches yet',
      'matchesEmptyDesc': 'Matches appear automatically when a found document matches a lost document.',
      'matchFound': 'Found',
      'matchLost': 'Lost',
      'matchIgnore': 'Ignore',
      'matchConfirm': 'Confirm',
      'matchOpenChat': 'Open chat',
      'matchVerifyId': 'Verify my identity',
      'matchConfirmThis': 'Confirm this match',
      'chatConnected': 'Connected',
      'chatDisconnected': 'Disconnected',
      'chatPlaceholder': 'Your message…',
      'chatSendLocation': 'Send recovery zone',
      'verifyTitle': 'Identity verification',
      'verifyDesc': 'To secure the handover, each participant must submit a selfie holding their ID document.',
      'verifyStart': 'Start verification',
      'verifyTakeSelfie': 'Take selfie',
      'verifySubmit': 'Submit',
      'verifyApproved': 'Identity verified. You can proceed with the handover.',
      'declarationsTitle': 'My declarations',
      'declarationsEmpty': 'No declarations yet',
      'declarationsEmptyDesc': 'Use the buttons below to declare a found or lost document.',
      'declarationFoundTitle': 'Found document',
      'declarationLostTitle': 'Lost document',
      'profileTitle': 'Your profile',
      'profileWelcome': 'Welcome to ReTurn!',
      'profileNameLabel': 'Full name',
      'profileContinue': 'Continue',
      'errorGeneric': 'An error occurred. Please try again.',
      'errorNetwork': 'Cannot reach the server. Check your connection.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirmDelete': 'Delete?',
      'confirmDeleteDesc': 'This declaration will be permanently deleted.',
      'selfieRequired': 'Selfie required',
      // Navigation
      'navDocuments': 'Documents',
      'navMatches': 'Matches',
      'navMessages': 'Messages',
      'navProfile': 'Profile',
      // Home / declarations
      'greetingHello': 'Hello',
      'greetingMorning': 'Good morning',
      'greetingAfternoon': 'Good afternoon',
      'greetingEvening': 'Good evening',
      // Sign in
      'loginWelcome': 'Welcome to ReTurn',
      'loginSubtitle': 'Sign in with your email or your Google account.',
      'loginOr': 'or',
      'loginGoogle': 'Continue with Google',
      'loginEmailLabel': 'Email address',
      'loginPasswordLabel': 'Password',
      'loginSignIn': 'Sign in',
      'loginCreateAccount': 'Create account',
      'loginNoAccount': "No account yet? Create one",
      'loginHaveAccount': 'Already have an account? Sign in',
      'loginForgot': 'Forgot password?',
      'loginEmailRequired': 'Email required',
      'loginEmailInvalid': 'Invalid email address',
      'loginPasswordRequired': 'Password required',
      'loginPasswordShort': 'At least 6 characters',
      'loginResetTitle': 'Reset password',
      'loginResetBody':
          'Enter your email and we will send you a reset link.',
      'loginResetSend': 'Send link',
      'loginResetSent':
          'Reset email sent. Check your inbox.',
      'loginSignUpTitle': 'Create your account',
      'loginSignUpSubtitle': 'Join ReTurn in seconds.',
      'loginConfirmPassword': 'Confirm password',
      'loginPasswordMismatch': 'Passwords do not match',
      'loginTerms': 'By continuing, you accept our terms of use and our '
          'privacy policy (CPDP).',
      // Declaration status
      'declStatusActive': 'Active',
      'declStatusMatched': 'Matched',
      'declStatusReturned': 'Returned',
      'declStatusCancelled': 'Cancelled',
      'homeHeroTitle': 'A document in your hands?',
      'homeHeroSubtitle': 'Report it, we\'ll handle the matching.',
      'homeFound': 'I found one',
      'homeLost': 'I lost one',
      'declMine': 'My declarations',
      'declNew': 'New',
      'declActive': 'active',
      'declLimitReached': 'Close a declaration to create a new one',
      'statActive': 'Active',
      'statMatched': 'Matched',
      'statRestituted': 'Returned',
      'declEmptyTitle': 'You have no declarations',
      'declEmptySubtitle': 'Lost a document?\nReport it in 60 seconds.',
      'declEmptyCta': 'Report a lost document',
      'declChooseTitle': 'What would you like to declare?',
      'declChooseFound': 'I found a document',
      'declChooseFoundSub': 'Help return it to its owner',
      'declChooseLost': 'I lost a document',
      'declChooseLostSub': 'Get notified as soon as it\'s found',
      'profileCompleteBanner': 'Complete your profile',
      'profileCompleteBannerSub': 'Name, photo and address — needed for the handover.',
      'retry': 'Retry',
      // Notifications
      'notifTitle': 'Notifications',
      'notifClearAll': 'Clear all',
      'notifLoadError': 'Unable to load notifications',
      'notifEmpty': 'No notifications',
      'notifEmptySub': 'You\'ll be alerted as soon as a\nmatching document is found.',
      'notifMatchFound': 'Matching document found!',
      'notifGeneric': 'Notification',
      'notifCorrespondence': '% match',
      // Declaration form (S-08/S-09)
      'declFormTitle': 'New declaration',
      'declTagFound': 'Found',
      'declTagLost': 'Lost',
      'declScanStep': 'Step 1 — Scan to auto-fill (AI)',
      'declScanned': 'Document scanned ✓',
      'declScanHint': 'Information is read automatically.',
      'declScanRedo': 'Tap to scan again.',
      'declOwnLostTitle': 'You are declaring your own document',
      'declOwnerLabel': 'Owner name (as on the document)',
      'declOwnerHint': 'E.g. ITOUA Francis',
      'declFieldRequired': 'Required field',
      'declWhichFound': 'Which document did you find?',
      'declWhichLost': 'Which document did you lose?',
      'declDossier': 'Documents in this file',
      'declAddOther': 'Add another document for this person',
      'declAddMore': 'Add a document',
      'declSamePerson': 'These documents belong to the same person and form a single file.',
      'declDocNumber': 'Document number (optional)',
      'declDocNumberHint': 'Improves matching accuracy',
      'declWhereWhenFound': 'Where and when did you find it?',
      'declWhereWhenLost': 'Where and when did you lose it?',
      'declPlaceFound': 'Place where you found it',
      'declPlaceLost': 'City / neighborhood of the loss',
      'declMyPosition': 'My location',
      'declPositionAdded': 'Location added',
      'declDate': 'Date',
      'declPhotosOptional': 'Photos (optional)',
      'declDescOptional': 'Description (optional)',
      'declSubmitFound': 'Declare found document',
      'declSubmitLost': 'Declare the loss',
      'declSubmitDossier': 'Declare the file',
      'declNoteFound': 'Sensitive data will be masked automatically.',
      'declNoteLost': 'You\'ll be alerted as soon as a document matches.',
      'declSavedFound': 'Found document declared.',
      'declSavedLost': 'Loss declared.',
      'declSaveError': 'Could not save. Check your connection and try again.',
      'declTakePhoto': 'Take a photo',
      'declFromGallery': 'Choose from gallery',
      // Matches (list)
      'matchesTitle2': 'My matches',
      'matchFilterAll': 'All',
      'matchFilterPending': 'Pending',
      'matchFilterConfirmed': 'Confirmed',
      'matchesSearching': 'We\'re continuously\nsearching for you.',
      'matchDeclareDoc': 'Declare a document',
      'matchStatusAwaitYou': 'Awaiting your confirmation',
      'matchStatusAwaitOther': 'Awaiting the other party',
      'matchStatusConfirmedVerify': 'Confirmed — Verify your identity',
      'matchStatusVerifiedChat': 'Verified — Chat',
      'matchStatusAwaitOwner': 'Awaiting the owner',
      'matchStatusIgnored': 'Ignored',
      'matchStatusClosed': 'Closed',
      // Chat
      'chatTitle': 'Conversation',
      'chatSecureHandover': 'Secure handover',
      'chatOrganizeReturn': 'Organize the handover',
      'chatSafetyBanner': 'Do not share sensitive information. Agree on a public or certified place for the handover.',
      'chatLoadError': 'Unable to load the conversation',
      'chatStart': 'Start the conversation',
      'chatClosed': 'This conversation is closed',
      'chatPhoneWarning': 'Avoid sharing your number: the handover happens in a public place via the app.',
      'chatLocationShared': 'Location shared',
      'chatSendFailed': 'Sending failed, try again.',
      'chatMessageHint': 'Your message…',
      'chatDateToday': 'Today',
      'chatDateYesterday': 'Yesterday',
      // Report
      'reportUser': 'Report this user',
      'reportReason': 'Reason',
      'reportDetails': 'Details (optional)',
      'reportSend': 'Send',
      'reportSent': 'Report sent. Thank you.',
      'reportFailed': 'Report failed.',
      'reasonFraud': 'Scam attempt',
      'reasonHarassment': 'Harassment / insults',
      'reasonFakeDoc': 'Forged document',
      'reasonIdentityTheft': 'Identity theft',
      'reasonInappropriate': 'Inappropriate content',
      'reasonOther': 'Other',
      // Document types
      'docCni': 'National ID Card',
      'docPassport': 'Passport',
      'docDrivingLicense': 'Driving license',
      'docVehicleReg': 'Vehicle registration',
      'docBirthCert': 'Birth certificate',
      'docStudentCard': 'Student card',
      'docBankCard': 'Bank card',
      'docDiploma': 'Diploma',
      'docOther': 'Other document',
      'declRemoveDoc': 'Remove this document',
      'commonUser': 'User',
      // Match detail
      'mdTitle': 'Match',
      'mdLoadError': 'Could not load the match',
      'mdScoreStrong': 'Strong match',
      'mdScoreProbable': 'Likely match',
      'mdScoreWeak': 'Weak match',
      'mdConfidence': 'confidence',
      'mdScoreExplain': 'Score based on: the name on the document (strong), '
          'the document number (strong), location (medium) '
          'and date consistency.',
      'mdFieldDocument': 'Document',
      'mdFieldNameOnDoc': 'Name on the document',
      'mdFieldLocation': 'Location',
      'mdFieldStatus': 'Status',
      'mdFieldDetectedOn': 'Detected on',
      'mdStatusPending': 'Awaiting verification',
      'mdStatusVerified': 'Identity verified',
      'mdStatusConfirmed': 'Confirmed',
      'mdStatusIgnored': 'Ignored',
      'mdStatusClosed': 'Closed',
      'mdOwnerVerified': 'Identity verified ✓ — you can now chat with '
          '{name} to arrange the pickup.',
      'mdOpenConversation': 'Open the conversation',
      'mdOwnerInReview': 'Your verification file is being reviewed by our '
          'team (within 24 h). You will be notified.',
      'mdOwnerRejectedReason': 'Verification rejected: {reason}. '
          'You can try again.',
      'mdOwnerRejected': 'Verification rejected. You can try again.',
      'mdRetryVerification': 'Retry verification',
      'mdOwnerPrompt': 'This document appears to be yours. Verify your '
          'identity to unlock the conversation with the person who found it.',
      'mdVerifyMyIdentity': 'Verify my identity',
      'mdNotMyDocument': 'This is not my document',
      'mdFinderVerified': '{name} verified their identity ✓ — you can now '
          'chat to arrange handing over the document.',
      'mdFinderWaiting': 'A potential owner was found. Awaiting their '
          'identity verification — you will be notified as soon as it is done.',
      'mdDocPhotos': 'Document photos',
      'mdProtectedData': 'Protected data',
      'mdStepDiscovered': 'Discovered',
      'mdStepVerified': 'Verified',
      'mdStepReturned': 'Returned',
      // Identity verification
      'verifTitle': 'Identity verification',
      'verifDobHelp': 'Your date of birth',
      'verifValidate': 'Confirm',
      'verifErrName': 'Please enter your full name.',
      'verifErrDob': 'Please enter your date of birth.',
      'verifErrDocNum':
          'The document number is required for this verification.',
      'verifErrMismatch': 'The information does not match. Please try again.',
      'verifErrGeneric': 'Something went wrong. Please try again.',
      'verifErrSelfie': 'Could not send the selfie. Please try again.',
      'verifErrDocPhoto': 'Could not send the photo. Please try again.',
      'verifIntroTitle': 'Let\'s confirm this document is really yours',
      'verifIntroBody': 'This step only serves to make sure you are truly the '
          'holder of the document, to prevent identity theft and fraud. '
          'No one else has access to it.',
      'verifStart': 'Start verification',
      'verifL1B1':
          'Quick check: your name and date of birth are enough.',
      'verifBulletConfidential':
          'Your answers are confidential and never shared.',
      'verifBulletProtect': 'This is what protects every owner on ReTurn.',
      'verifL2B1':
          'Two quick steps: a few details from the document, then a selfie.',
      'verifL2B2': 'Your answers and your selfie stay private.',
      'verifL3B1': 'Three steps: document details, a selfie, then a photo '
          'of the document.',
      'verifL3B2': 'Our team reviews your file within 24 h for maximum security.',
      'verifL3B3': 'All your data stays private and protected.',
      'verifQTitle': 'Verification questions',
      'verifQSubtitle3': 'Enter your name as it appears on the document, your '
          'date of birth and the document number.',
      'verifQSubtitle': 'Enter your name as it appears on the document and '
          'your date of birth.',
      'verifFieldName': 'Full name on the document',
      'verifFieldDob': 'Date of birth',
      'verifDobSelect': 'Select…',
      'verifFieldDocNum': 'Document number',
      'verifFieldDocNumHelper': 'Required for this enhanced verification.',
      'verifSubmit': 'Verify',
      'verifSelfieTitle': 'One last step: your selfie',
      'verifSelfieBody': 'Correct answers ✓. Take a selfie to confirm it\'s '
          'really you. This photo is used only for verification and stays private.',
      'verifSelfieBtn': 'Take a selfie',
      'verifDocTitle': 'Photo of a supporting document',
      'verifDocBody': 'Take a photo of a document proving your identity '
          '(old ID card, receipt, birth certificate…). Our team reviews it '
          'within 24 h — it is never shared with the other party.',
      'verifDocBtn': 'Photograph the document',
      'verifReviewTitle': 'File under review',
      'verifReviewBody': 'Thank you! Your file is complete. Our team is '
          'reviewing it within 24 h — you will be notified once approved.',
      'verifUnderstood': 'Got it',
      'verifRejectedTitle': 'Verification not approved',
      'verifRejectedReason': 'Reason: {reason}',
      'verifRejectedBody':
          'The items provided did not confirm your identity.',
      'verifClose': 'Close',
      'verifDoneTitle': 'Identity verified',
      'verifDoneBody': 'Thank you! You can now arrange the return with '
          'full confidence.',
      'verifDoneRestitution': 'Arrange the return',
      'verifDoneLater': 'Later',
      // Return handover
      'restTitle': 'Return',
      'restLoadError': 'Could not load the return.',
      'restProofTitle': 'Proof photo required',
      'restProofBody': 'Take a photo of the document at the moment of '
          'handover. It protects both parties in case of a dispute.',
      'restTakePhoto': 'Take the photo',
      'restActionFail': 'Action failed, please try again.',
      'restMeetingSaveFail': 'Could not save the location.',
      'restPosUnavailable': 'Location unavailable — check your GPS.',
      'restZonesLoadFail': 'Could not load places. Please try again.',
      'restNoZones': 'No public place listed yet.',
      'restRateThanks': 'Thank you for your review!',
      'restRateFail': 'Could not submit the review (already rated?).',
      'restMeetNearby': 'Suggest a public place nearby',
      'restMeetNearbySub': 'Uses your GPS location',
      'restMeetZone': 'Choose a certified zone',
      'restMeetZoneSub': 'Police station, city hall, campus — recommended',
      'restMeetManual': 'Enter another place',
      'restNearbyTitle': 'Public places nearby',
      'restMeetDialogTitle': 'Meeting place',
      'restMeetHint': 'E.g. Bonanjo police station',
      'restMeetHelper': 'Prefer a public or certified place.',
      'restSave': 'Save',
      'restNotReadyTitle': 'Return not open yet',
      'restNotReadyBody': 'Both parties must first confirm the match. '
          'The return will open automatically afterwards.',
      'restDoneStatus': 'Document recovered! 🎉 Thank you for using ReTurn.',
      'restIConfirmedWaiting': 'You confirmed ✓ — waiting for the other '
          'party\'s confirmation.',
      'restStep1Of3': 'Step 1/3 — Agree on a public place for the handover.',
      'restStep2Of3': 'Step 2/3 — Confirm once the document is handed over '
          'in person.',
      'restMeetingUnset': 'Not set — agree on a public or certified place.',
      'restEdit': 'Edit',
      'restChoose': 'Choose',
      'restHandoffTitle': 'Handover confirmation',
      'restRoleOwner': 'Owner',
      'restRoleFinder': 'Finder',
      'restConfirmed': 'confirmed ✓',
      'restPending': 'pending',
      'restProofCardTitle': 'Proof photo',
      'restProofCardSub': '{count} photo(s) saved — protects both parties.',
      'restChooseMeetingBtn': 'Choose the meeting place',
      'restNextStepHint': 'Next step: confirm the handover once the document '
          'has been exchanged in person.',
      'restIGotDoc': 'I got my document back',
      'restIGaveDoc': 'I handed over the document',
      'restWaitingOther': 'Waiting for the other party\'s confirmation. '
          'You will be notified as soon as it is done.',
      'restRatedTitle': 'Review sent',
      'restRatedSub': 'Thank you! Your rating helps the ReTurn community.',
      'restRateQuestion': 'How did the handover with {name} go?',
      'restOtherParty': 'the other party',
      'restStepRdv': 'Meeting',
      'restStepHandover': 'Handover',
      'restStepRating': 'Rating',
      'restCommentLabel': 'Comment (optional)',
      'restSendRating': 'Send my review',
      'restConfettiTitle': 'Document recovered!',
      'restReputation': 'Reputation: {value}/10',
      // Profile
      'profTitle': 'Profile',
      'profLoading': 'Loading profile…',
      'profErrorTitle': 'Could not load the profile',
      'profLogout': 'Log out',
      'profFieldName': 'Full name',
      'profFieldContact': 'Phone or email',
      'profFieldDob': 'Date of birth',
      'profFieldGender': 'Gender',
      'profFieldCity': 'City',
      'profFieldIdNum': 'ID / Passport number',
      'profCompleteTitle': 'Complete your profile in 1 minute',
      'profCompleteBody': 'This information is used to verify your identity '
          'when recovering a document.',
      'profCompleteNow': 'Complete now',
      'profDeleteTitle': 'Delete my account',
      'profDeleteBody': 'This action is permanent and irreversible. Your '
          'account, declarations, matches and messages will be deleted in '
          'accordance with your right to erasure (GDPR/CPDP).'
          '\n\nDo you really want to continue?',
      'profDeleteConfirm': 'Delete permanently',
      'profDeleteFailed': 'Deletion failed, please try again.',
      'profSectionMyProfile': 'My profile',
      'profSectionAppearance': 'Appearance',
      'profSectionLanguage': 'Language',
      'profSectionSecurity': 'Security',
      'profSectionHelp': 'Help & support',
      'profSectionAbout': 'About',
      'profSectionDanger': 'Danger zone',
      'profEditProfile': 'Edit / complete my profile',
      'profMyReturns': 'My returns',
      'profZones': 'Pickup zones',
      'profThemeLight': 'Light',
      'profThemeDark': 'Dark',
      'profLangSystem': 'System language',
      'profHelpFaq': 'Help & FAQ',
      'profContactSupport': 'Contact support',
      'profPrivacy': 'Privacy',
      'profVersion': 'Version',
      'profDeleteAccount': 'Delete my account (GDPR)',
      'profFieldsFilled': '{filled}/{total} fields filled in',
      'profEditSubtitle': 'Fill in your details. The photo is changed from '
          'the avatar.',
      'profNameInputLabel': 'Full name (first and last)',
      'profNameInputHelper': 'Cannot be changed once saved.',
      'profPhoneLabel': 'Phone number',
      'profAddPhoneLabel': 'Add a number (+237…)',
      'profAddPhoneHelper': 'To also sign in via SMS.',
      'profEmailLabel': 'Email',
      'profAddEmailLabel': 'Add an email',
      'profAddEmailHelper': 'To also sign in via Google.',
      'profDobHelper': 'Used to verify your identity.',
      'profGenderMale': 'Male',
      'profGenderFemale': 'Female',
      'profGenderOther': 'Other',
      'profAddressLabel': 'Current address',
      'profIdHelper': 'Optional — speeds up verification.',
      'profUpdated': 'Profile updated',
      'profSavePartialError': 'Your information was saved ✓ — but: {err} '
          'Clear this field or use another contact detail.',
      'profReadOnlyHelper': 'Verification required to edit.',
      'profAvatarUpdated': 'Photo updated',
      'profAvatarCancelled': 'Cancelled',
      'profBadgeComplete': 'Complete',
      'profBadgeIncomplete': 'Incomplete',
      'profBiometricTitle': 'Biometric unlock',
      'profBiometricSub': 'Fingerprint or face on open',
      'profBiometricNone': 'No biometrics set up on this device.',
      'profBiometricReason': 'Enable biometric lock',
      'profChangePhoto': 'Change profile photo',
      'errorTitle': 'Oops, something went wrong',
      // Multi-document declaration (auto sorting)
      'mdocTitle': 'Declare multiple documents',
      'mdocIntro': 'Add or photograph all the documents. The app reads each '
          'file and automatically groups documents by person — one folder '
          'per owner.',
      'mdocAddGallery': 'Add from gallery',
      'mdocTakePhotos': 'Take a photo',
      'mdocAnalyzing': 'Analysing documents…',
      'mdocDossierOwner': 'Folder owner',
      'mdocOwnerHint': 'Name on the documents',
      'mdocNoName': 'No name detected',
      'mdocRemove': 'Remove',
      'mdocAddMore': 'Add more documents',
      'mdocLocation': 'Location (optional, improves matching)',
      'mdocEmpty': 'No document added yet.',
      'mdocDetected': '{n} person(s) detected',
      'mdocSubmit': 'Declare {n} folder(s)',
      'mdocSuccess': '{n} folder(s) declared ✓',
      'mdocError': 'Could not save. Please try again.',
      'mdocOwnerRequired': 'Enter the owner name for each folder.',
      'mdocChooseSub': 'Wallet, several people — automatic sorting',
      'dossierBadge': 'FOLDER',
      'dossierDocsCount': '{n} documents',
      'dossierTitle': 'Folder',
      'dossierEmpty': 'This folder is empty.',
    },
  };

  String _t(String key) {
    final lang = locale.languageCode;
    return _strings[lang]?[key] ?? _strings['fr']?[key] ?? key;
  }

  String get appName => _t('appName');
  // Navigation
  String get navDocuments => _t('navDocuments');
  String get navMatches => _t('navMatches');
  String get navMessages => _t('navMessages');
  String get navProfile => _t('navProfile');
  // Accueil / déclarations
  String get greetingHello => _t('greetingHello');

  // Connexion
  String get loginWelcome => _t('loginWelcome');
  String get loginSubtitle => _t('loginSubtitle');
  String get loginOr => _t('loginOr');
  String get loginGoogle => _t('loginGoogle');
  String get loginEmailLabel => _t('loginEmailLabel');
  String get loginPasswordLabel => _t('loginPasswordLabel');
  String get loginSignIn => _t('loginSignIn');
  String get loginCreateAccount => _t('loginCreateAccount');
  String get loginNoAccount => _t('loginNoAccount');
  String get loginHaveAccount => _t('loginHaveAccount');
  String get loginForgot => _t('loginForgot');
  String get loginEmailRequired => _t('loginEmailRequired');
  String get loginEmailInvalid => _t('loginEmailInvalid');
  String get loginPasswordRequired => _t('loginPasswordRequired');
  String get loginPasswordShort => _t('loginPasswordShort');
  String get loginResetTitle => _t('loginResetTitle');
  String get loginResetBody => _t('loginResetBody');
  String get loginResetSend => _t('loginResetSend');
  String get loginResetSent => _t('loginResetSent');
  String get loginSignUpTitle => _t('loginSignUpTitle');
  String get loginSignUpSubtitle => _t('loginSignUpSubtitle');
  String get loginConfirmPassword => _t('loginConfirmPassword');
  String get loginPasswordMismatch => _t('loginPasswordMismatch');
  String get loginTerms => _t('loginTerms');
  String get declStatusActive => _t('declStatusActive');
  String get declStatusMatched => _t('declStatusMatched');
  String get declStatusReturned => _t('declStatusReturned');
  String get declStatusCancelled => _t('declStatusCancelled');

  /// Salutation adaptée à l'heure locale (matin / après-midi / soir).
  String greeting(int hour) {
    if (hour >= 5 && hour < 12) return _t('greetingMorning');
    if (hour >= 12 && hour < 18) return _t('greetingAfternoon');
    return _t('greetingEvening');
  }
  String get homeHeroTitle => _t('homeHeroTitle');
  String get homeHeroSubtitle => _t('homeHeroSubtitle');
  String get homeFound => _t('homeFound');
  String get homeLost => _t('homeLost');
  String get declMine => _t('declMine');
  String get declNew => _t('declNew');
  String get declActive => _t('declActive');
  String get declLimitReached => _t('declLimitReached');
  String get statActive => _t('statActive');
  String get statMatched => _t('statMatched');
  String get statRestituted => _t('statRestituted');
  String get declEmptyTitle => _t('declEmptyTitle');
  String get declEmptySubtitle => _t('declEmptySubtitle');
  String get declEmptyCta => _t('declEmptyCta');
  String get declChooseTitle => _t('declChooseTitle');
  String get declChooseFound => _t('declChooseFound');
  String get declChooseFoundSub => _t('declChooseFoundSub');
  String get declChooseLost => _t('declChooseLost');
  String get declChooseLostSub => _t('declChooseLostSub');
  String get profileCompleteBanner => _t('profileCompleteBanner');
  String get profileCompleteBannerSub => _t('profileCompleteBannerSub');
  String get retry => _t('retry');
  String get notifTitle => _t('notifTitle');
  String get notifClearAll => _t('notifClearAll');
  String get notifLoadError => _t('notifLoadError');
  String get notifEmpty => _t('notifEmpty');
  String get notifEmptySub => _t('notifEmptySub');
  String get notifMatchFound => _t('notifMatchFound');
  String get notifGeneric => _t('notifGeneric');
  String get notifCorrespondence => _t('notifCorrespondence');
  // Formulaire de déclaration
  String get declFormTitle => _t('declFormTitle');
  String get declTagFound => _t('declTagFound');
  String get declTagLost => _t('declTagLost');
  String get declScanStep => _t('declScanStep');
  String get declScanned => _t('declScanned');
  String get declScanHint => _t('declScanHint');
  String get declScanRedo => _t('declScanRedo');
  String get declOwnLostTitle => _t('declOwnLostTitle');
  String get declOwnerLabel => _t('declOwnerLabel');
  String get declOwnerHint => _t('declOwnerHint');
  String get declFieldRequired => _t('declFieldRequired');
  String get declWhichFound => _t('declWhichFound');
  String get declWhichLost => _t('declWhichLost');
  String get declDossier => _t('declDossier');
  String get declAddOther => _t('declAddOther');
  String get declAddMore => _t('declAddMore');
  String get declSamePerson => _t('declSamePerson');
  String get declDocNumber => _t('declDocNumber');
  String get declDocNumberHint => _t('declDocNumberHint');
  String get declWhereWhenFound => _t('declWhereWhenFound');
  String get declWhereWhenLost => _t('declWhereWhenLost');
  String get declPlaceFound => _t('declPlaceFound');
  String get declPlaceLost => _t('declPlaceLost');
  String get declMyPosition => _t('declMyPosition');
  String get declPositionAdded => _t('declPositionAdded');
  String get declDate => _t('declDate');
  String get declPhotosOptional => _t('declPhotosOptional');
  String get declDescOptional => _t('declDescOptional');
  String get declSubmitFound => _t('declSubmitFound');
  String get declSubmitLost => _t('declSubmitLost');
  String get declSubmitDossier => _t('declSubmitDossier');
  String get declNoteFound => _t('declNoteFound');
  String get declNoteLost => _t('declNoteLost');
  String get declSavedFound => _t('declSavedFound');
  String get declSavedLost => _t('declSavedLost');
  String get declSaveError => _t('declSaveError');
  String get declTakePhoto => _t('declTakePhoto');
  String get declFromGallery => _t('declFromGallery');
  // Matchs (liste)
  String get matchesTitle2 => _t('matchesTitle2');
  String get matchFilterAll => _t('matchFilterAll');
  String get matchFilterPending => _t('matchFilterPending');
  String get matchFilterConfirmed => _t('matchFilterConfirmed');
  String get matchesSearching => _t('matchesSearching');
  String get matchDeclareDoc => _t('matchDeclareDoc');
  String get matchStatusAwaitYou => _t('matchStatusAwaitYou');
  String get matchStatusAwaitOther => _t('matchStatusAwaitOther');
  String get matchStatusConfirmedVerify => _t('matchStatusConfirmedVerify');
  String get matchStatusVerifiedChat => _t('matchStatusVerifiedChat');
  String get matchStatusAwaitOwner => _t('matchStatusAwaitOwner');
  String get matchStatusIgnored => _t('matchStatusIgnored');
  String get matchStatusClosed => _t('matchStatusClosed');
  // Chat
  String get chatTitle => _t('chatTitle');
  String get chatSecureHandover => _t('chatSecureHandover');
  String get chatOrganizeReturn => _t('chatOrganizeReturn');
  String get chatSafetyBanner => _t('chatSafetyBanner');
  String get chatLoadError => _t('chatLoadError');
  String get chatStart => _t('chatStart');
  String get chatClosed => _t('chatClosed');
  String get chatPhoneWarning => _t('chatPhoneWarning');
  String get chatLocationShared => _t('chatLocationShared');
  String get chatSendFailed => _t('chatSendFailed');
  String get chatMessageHint => _t('chatMessageHint');
  String get chatDateToday => _t('chatDateToday');
  String get chatDateYesterday => _t('chatDateYesterday');
  // Signalement
  String get reportUser => _t('reportUser');
  String get reportReason => _t('reportReason');
  String get reportDetails => _t('reportDetails');
  String get reportSend => _t('reportSend');
  String get reportSent => _t('reportSent');
  String get reportFailed => _t('reportFailed');
  String get reasonFraud => _t('reasonFraud');
  String get reasonHarassment => _t('reasonHarassment');
  String get reasonFakeDoc => _t('reasonFakeDoc');
  String get reasonIdentityTheft => _t('reasonIdentityTheft');
  String get reasonInappropriate => _t('reasonInappropriate');
  String get reasonOther => _t('reasonOther');

  /// Libellé traduit d'un type de document (clé backend → libellé localisé).
  String docType(String key) {
    switch (key.toLowerCase()) {
      case 'cni':
        return _t('docCni');
      case 'passport':
        return _t('docPassport');
      case 'driving_license':
        return _t('docDrivingLicense');
      case 'vehicle_registration':
        return _t('docVehicleReg');
      case 'birth_certificate':
        return _t('docBirthCert');
      case 'student_card':
        return _t('docStudentCard');
      case 'bank_card':
        return _t('docBankCard');
      case 'diploma':
        return _t('docDiploma');
      case 'other':
        return _t('docOther');
      default:
        return key;
    }
  }

  String get declRemoveDoc => _t('declRemoveDoc');
  String get commonUser => _t('commonUser');
  // Détail de la correspondance
  String get mdTitle => _t('mdTitle');
  String get mdLoadError => _t('mdLoadError');
  String get mdScoreStrong => _t('mdScoreStrong');
  String get mdScoreProbable => _t('mdScoreProbable');
  String get mdScoreWeak => _t('mdScoreWeak');
  String get mdConfidence => _t('mdConfidence');
  String get mdScoreExplain => _t('mdScoreExplain');
  String get mdFieldDocument => _t('mdFieldDocument');
  String get mdFieldNameOnDoc => _t('mdFieldNameOnDoc');
  String get mdFieldLocation => _t('mdFieldLocation');
  String get mdFieldStatus => _t('mdFieldStatus');
  String get mdFieldDetectedOn => _t('mdFieldDetectedOn');
  String get mdStatusPending => _t('mdStatusPending');
  String get mdStatusVerified => _t('mdStatusVerified');
  String get mdStatusConfirmed => _t('mdStatusConfirmed');
  String get mdStatusIgnored => _t('mdStatusIgnored');
  String get mdStatusClosed => _t('mdStatusClosed');
  String mdOwnerVerified(String name) =>
      _t('mdOwnerVerified').replaceAll('{name}', name);
  String get mdOpenConversation => _t('mdOpenConversation');
  String get mdOwnerInReview => _t('mdOwnerInReview');
  String mdOwnerRejectedReason(String reason) =>
      _t('mdOwnerRejectedReason').replaceAll('{reason}', reason);
  String get mdOwnerRejected => _t('mdOwnerRejected');
  String get mdRetryVerification => _t('mdRetryVerification');
  String get mdOwnerPrompt => _t('mdOwnerPrompt');
  String get mdVerifyMyIdentity => _t('mdVerifyMyIdentity');
  String get mdNotMyDocument => _t('mdNotMyDocument');
  String mdFinderVerified(String name) =>
      _t('mdFinderVerified').replaceAll('{name}', name);
  String get mdFinderWaiting => _t('mdFinderWaiting');
  String get mdDocPhotos => _t('mdDocPhotos');
  String get mdProtectedData => _t('mdProtectedData');
  String get mdStepDiscovered => _t('mdStepDiscovered');
  String get mdStepVerified => _t('mdStepVerified');
  String get mdStepReturned => _t('mdStepReturned');
  // Vérification d'identité
  String get verifTitle => _t('verifTitle');
  String get verifDobHelp => _t('verifDobHelp');
  String get verifValidate => _t('verifValidate');
  String get verifErrName => _t('verifErrName');
  String get verifErrDob => _t('verifErrDob');
  String get verifErrDocNum => _t('verifErrDocNum');
  String get verifErrMismatch => _t('verifErrMismatch');
  String get verifErrGeneric => _t('verifErrGeneric');
  String get verifErrSelfie => _t('verifErrSelfie');
  String get verifErrDocPhoto => _t('verifErrDocPhoto');
  String get verifIntroTitle => _t('verifIntroTitle');
  String get verifIntroBody => _t('verifIntroBody');
  String get verifStart => _t('verifStart');
  String get verifL1B1 => _t('verifL1B1');
  String get verifBulletConfidential => _t('verifBulletConfidential');
  String get verifBulletProtect => _t('verifBulletProtect');
  String get verifL2B1 => _t('verifL2B1');
  String get verifL2B2 => _t('verifL2B2');
  String get verifL3B1 => _t('verifL3B1');
  String get verifL3B2 => _t('verifL3B2');
  String get verifL3B3 => _t('verifL3B3');
  String get verifQTitle => _t('verifQTitle');
  String get verifQSubtitle3 => _t('verifQSubtitle3');
  String get verifQSubtitle => _t('verifQSubtitle');
  String get verifFieldName => _t('verifFieldName');
  String get verifFieldDob => _t('verifFieldDob');
  String get verifDobSelect => _t('verifDobSelect');
  String get verifFieldDocNum => _t('verifFieldDocNum');
  String get verifFieldDocNumHelper => _t('verifFieldDocNumHelper');
  String get verifSubmit => _t('verifSubmit');
  String get verifSelfieTitle => _t('verifSelfieTitle');
  String get verifSelfieBody => _t('verifSelfieBody');
  String get verifSelfieBtn => _t('verifSelfieBtn');
  String get verifDocTitle => _t('verifDocTitle');
  String get verifDocBody => _t('verifDocBody');
  String get verifDocBtn => _t('verifDocBtn');
  String get verifReviewTitle => _t('verifReviewTitle');
  String get verifReviewBody => _t('verifReviewBody');
  String get verifUnderstood => _t('verifUnderstood');
  String get verifRejectedTitle => _t('verifRejectedTitle');
  String verifRejectedReason(String reason) =>
      _t('verifRejectedReason').replaceAll('{reason}', reason);
  String get verifRejectedBody => _t('verifRejectedBody');
  String get verifClose => _t('verifClose');
  String get verifDoneTitle => _t('verifDoneTitle');
  String get verifDoneBody => _t('verifDoneBody');
  String get verifDoneRestitution => _t('verifDoneRestitution');
  String get verifDoneLater => _t('verifDoneLater');
  // Restitution
  String get restTitle => _t('restTitle');
  String get restLoadError => _t('restLoadError');
  String get restProofTitle => _t('restProofTitle');
  String get restProofBody => _t('restProofBody');
  String get restTakePhoto => _t('restTakePhoto');
  String get restActionFail => _t('restActionFail');
  String get restMeetingSaveFail => _t('restMeetingSaveFail');
  String get restPosUnavailable => _t('restPosUnavailable');
  String get restZonesLoadFail => _t('restZonesLoadFail');
  String get restNoZones => _t('restNoZones');
  String get restRateThanks => _t('restRateThanks');
  String get restRateFail => _t('restRateFail');
  String get restMeetNearby => _t('restMeetNearby');
  String get restMeetNearbySub => _t('restMeetNearbySub');
  String get restMeetZone => _t('restMeetZone');
  String get restMeetZoneSub => _t('restMeetZoneSub');
  String get restMeetManual => _t('restMeetManual');
  String get restNearbyTitle => _t('restNearbyTitle');
  String get restMeetDialogTitle => _t('restMeetDialogTitle');
  String get restMeetHint => _t('restMeetHint');
  String get restMeetHelper => _t('restMeetHelper');
  String get restSave => _t('restSave');
  String get restNotReadyTitle => _t('restNotReadyTitle');
  String get restNotReadyBody => _t('restNotReadyBody');
  String get restDoneStatus => _t('restDoneStatus');
  String get restIConfirmedWaiting => _t('restIConfirmedWaiting');
  String get restStep1Of3 => _t('restStep1Of3');
  String get restStep2Of3 => _t('restStep2Of3');
  String get restMeetingUnset => _t('restMeetingUnset');
  String get restEdit => _t('restEdit');
  String get restChoose => _t('restChoose');
  String get restHandoffTitle => _t('restHandoffTitle');
  String get restRoleOwner => _t('restRoleOwner');
  String get restRoleFinder => _t('restRoleFinder');
  String get restConfirmed => _t('restConfirmed');
  String get restPending => _t('restPending');
  String get restProofCardTitle => _t('restProofCardTitle');
  String restProofCardSub(int count) =>
      _t('restProofCardSub').replaceAll('{count}', '$count');
  String get restChooseMeetingBtn => _t('restChooseMeetingBtn');
  String get restNextStepHint => _t('restNextStepHint');
  String get restIGotDoc => _t('restIGotDoc');
  String get restIGaveDoc => _t('restIGaveDoc');
  String get restWaitingOther => _t('restWaitingOther');
  String get restRatedTitle => _t('restRatedTitle');
  String get restRatedSub => _t('restRatedSub');
  String restRateQuestion(String name) =>
      _t('restRateQuestion').replaceAll('{name}', name);
  String get restOtherParty => _t('restOtherParty');
  String get restStepRdv => _t('restStepRdv');
  String get restStepHandover => _t('restStepHandover');
  String get restStepRating => _t('restStepRating');
  String get restCommentLabel => _t('restCommentLabel');
  String get restSendRating => _t('restSendRating');
  String get restConfettiTitle => _t('restConfettiTitle');
  String restReputation(String value) =>
      _t('restReputation').replaceAll('{value}', value);
  // Profil
  String get profTitle => _t('profTitle');
  String get profLoading => _t('profLoading');
  String get profErrorTitle => _t('profErrorTitle');
  String get profLogout => _t('profLogout');
  String get profFieldName => _t('profFieldName');
  String get profFieldContact => _t('profFieldContact');
  String get profFieldDob => _t('profFieldDob');
  String get profFieldGender => _t('profFieldGender');
  String get profFieldCity => _t('profFieldCity');
  String get profFieldIdNum => _t('profFieldIdNum');
  String get profCompleteTitle => _t('profCompleteTitle');
  String get profCompleteBody => _t('profCompleteBody');
  String get profCompleteNow => _t('profCompleteNow');
  String get profDeleteTitle => _t('profDeleteTitle');
  String get profDeleteBody => _t('profDeleteBody');
  String get profDeleteConfirm => _t('profDeleteConfirm');
  String get profDeleteFailed => _t('profDeleteFailed');
  String get profSectionMyProfile => _t('profSectionMyProfile');
  String get profSectionAppearance => _t('profSectionAppearance');
  String get profSectionLanguage => _t('profSectionLanguage');
  String get profSectionSecurity => _t('profSectionSecurity');
  String get profSectionHelp => _t('profSectionHelp');
  String get profSectionAbout => _t('profSectionAbout');
  String get profSectionDanger => _t('profSectionDanger');
  String get profEditProfile => _t('profEditProfile');
  String get profMyReturns => _t('profMyReturns');
  String get profZones => _t('profZones');
  String get profThemeLight => _t('profThemeLight');
  String get profThemeDark => _t('profThemeDark');
  String get profLangSystem => _t('profLangSystem');
  String get profHelpFaq => _t('profHelpFaq');
  String get profContactSupport => _t('profContactSupport');
  String get profPrivacy => _t('profPrivacy');
  String get profVersion => _t('profVersion');
  String get profDeleteAccount => _t('profDeleteAccount');
  String profFieldsFilled(int filled, int total) => _t('profFieldsFilled')
      .replaceAll('{filled}', '$filled')
      .replaceAll('{total}', '$total');
  String get profEditSubtitle => _t('profEditSubtitle');
  String get profNameInputLabel => _t('profNameInputLabel');
  String get profNameInputHelper => _t('profNameInputHelper');
  String get profPhoneLabel => _t('profPhoneLabel');
  String get profAddPhoneLabel => _t('profAddPhoneLabel');
  String get profAddPhoneHelper => _t('profAddPhoneHelper');
  String get profEmailLabel => _t('profEmailLabel');
  String get profAddEmailLabel => _t('profAddEmailLabel');
  String get profAddEmailHelper => _t('profAddEmailHelper');
  String get profDobHelper => _t('profDobHelper');
  String get profGenderMale => _t('profGenderMale');
  String get profGenderFemale => _t('profGenderFemale');
  String get profGenderOther => _t('profGenderOther');
  String get profAddressLabel => _t('profAddressLabel');
  String get profIdHelper => _t('profIdHelper');
  String get profUpdated => _t('profUpdated');
  String profSavePartialError(String err) =>
      _t('profSavePartialError').replaceAll('{err}', err);
  String get profReadOnlyHelper => _t('profReadOnlyHelper');
  String get profAvatarUpdated => _t('profAvatarUpdated');
  String get profAvatarCancelled => _t('profAvatarCancelled');
  String get profBadgeComplete => _t('profBadgeComplete');
  String get profBadgeIncomplete => _t('profBadgeIncomplete');
  String get profBiometricTitle => _t('profBiometricTitle');
  String get profBiometricSub => _t('profBiometricSub');
  String get profBiometricNone => _t('profBiometricNone');
  String get profBiometricReason => _t('profBiometricReason');
  String get profChangePhoto => _t('profChangePhoto');
  String get errorTitle => _t('errorTitle');
  // Déclaration multi-documents
  String get mdocTitle => _t('mdocTitle');
  String get mdocIntro => _t('mdocIntro');
  String get mdocAddGallery => _t('mdocAddGallery');
  String get mdocTakePhotos => _t('mdocTakePhotos');
  String get mdocAnalyzing => _t('mdocAnalyzing');
  String get mdocDossierOwner => _t('mdocDossierOwner');
  String get mdocOwnerHint => _t('mdocOwnerHint');
  String get mdocNoName => _t('mdocNoName');
  String get mdocRemove => _t('mdocRemove');
  String get mdocAddMore => _t('mdocAddMore');
  String get mdocLocation => _t('mdocLocation');
  String get mdocEmpty => _t('mdocEmpty');
  String mdocDetected(int n) => _t('mdocDetected').replaceAll('{n}', '$n');
  String mdocSubmit(int n) => _t('mdocSubmit').replaceAll('{n}', '$n');
  String mdocSuccess(int n) => _t('mdocSuccess').replaceAll('{n}', '$n');
  String get mdocError => _t('mdocError');
  String get mdocOwnerRequired => _t('mdocOwnerRequired');
  String get mdocChooseSub => _t('mdocChooseSub');
  String get dossierBadge => _t('dossierBadge');
  String dossierDocsCount(int n) =>
      _t('dossierDocsCount').replaceAll('{n}', '$n');
  String get dossierTitle => _t('dossierTitle');
  String get dossierEmpty => _t('dossierEmpty');

  /// Libellé d'affichage d'un genre (la valeur stockée reste en français).
  String genderLabel(String value) {
    switch (value) {
      case 'Homme':
        return profGenderMale;
      case 'Femme':
        return profGenderFemale;
      case 'Autre':
        return profGenderOther;
      default:
        return value;
    }
  }

  String get settingsTitle => _t('settingsTitle');
  String get settingsTheme => _t('settingsTheme');
  String get settingsThemeLight => _t('settingsThemeLight');
  String get settingsThemeDark => _t('settingsThemeDark');
  String get settingsThemeNightBlue => _t('settingsThemeNightBlue');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsLanguageSystem => _t('settingsLanguageSystem');
  String get settingsLanguageFr => _t('settingsLanguageFr');
  String get settingsLanguageEn => _t('settingsLanguageEn');
  String get settingsAbout => _t('settingsAbout');
  String get settingsVersion => _t('settingsVersion');
  String get settingsLogout => _t('settingsLogout');
  String get homeGreeting => _t('homeGreeting');
  String get homeQuestion => _t('homeQuestion');
  String get homeFoundDoc => _t('homeFoundDoc');
  String get homeFoundDocSub => _t('homeFoundDocSub');
  String get homeLostDoc => _t('homeLostDoc');
  String get homeLostDocSub => _t('homeLostDocSub');
  String get homeDeclarations => _t('homeDeclarations');
  String get homeDeclarationsSub => _t('homeDeclarationsSub');
  String get homeMatches => _t('homeMatches');
  String get homeMatchesSub => _t('homeMatchesSub');
  String get onboardingSkip => _t('onboardingSkip');
  String get onboardingNext => _t('onboardingNext');
  String get onboardingStart => _t('onboardingStart');
  String get onboarding1Title => _t('onboarding1Title');
  String get onboarding1Body => _t('onboarding1Body');
  String get onboarding2Title => _t('onboarding2Title');
  String get onboarding2Body => _t('onboarding2Body');
  String get onboarding3Title => _t('onboarding3Title');
  String get onboarding3Body => _t('onboarding3Body');
  String get phoneInputTitle => _t('phoneInputTitle');
  String get phoneInputSubtitle => _t('phoneInputSubtitle');
  String get phoneInputLabel => _t('phoneInputLabel');
  String get phoneInputReceive => _t('phoneInputReceive');
  String get phoneInputOr => _t('phoneInputOr');
  String get phoneInputGoogle => _t('phoneInputGoogle');
  String get phoneInputTerms => _t('phoneInputTerms');
  String get phoneValidRequired => _t('phoneValidRequired');
  String get phoneValidLength => _t('phoneValidLength');
  String get otpTitle => _t('otpTitle');
  String get otpSentTo => _t('otpSentTo');
  String get otpResendIn => _t('otpResendIn');
  String get otpResend => _t('otpResend');
  String get otpVerify => _t('otpVerify');
  String get splashTagline => _t('splashTagline');
  String get matchesTitle => _t('matchesTitle');
  String get matchesEmpty => _t('matchesEmpty');
  String get matchesEmptyDesc => _t('matchesEmptyDesc');
  String get matchFound => _t('matchFound');
  String get matchLost => _t('matchLost');
  String get matchIgnore => _t('matchIgnore');
  String get matchConfirm => _t('matchConfirm');
  String get matchOpenChat => _t('matchOpenChat');
  String get matchVerifyId => _t('matchVerifyId');
  String get matchConfirmThis => _t('matchConfirmThis');
  String get chatConnected => _t('chatConnected');
  String get chatDisconnected => _t('chatDisconnected');
  String get chatPlaceholder => _t('chatPlaceholder');
  String get chatSendLocation => _t('chatSendLocation');
  String get verifyTitle => _t('verifyTitle');
  String get verifyDesc => _t('verifyDesc');
  String get verifyStart => _t('verifyStart');
  String get verifyTakeSelfie => _t('verifyTakeSelfie');
  String get verifySubmit => _t('verifySubmit');
  String get verifyApproved => _t('verifyApproved');
  String get declarationsTitle => _t('declarationsTitle');
  String get declarationsEmpty => _t('declarationsEmpty');
  String get declarationsEmptyDesc => _t('declarationsEmptyDesc');
  String get declarationFoundTitle => _t('declarationFoundTitle');
  String get declarationLostTitle => _t('declarationLostTitle');
  String get profileTitle => _t('profileTitle');
  String get profileWelcome => _t('profileWelcome');
  String get profileNameLabel => _t('profileNameLabel');
  String get profileContinue => _t('profileContinue');
  String get errorGeneric => _t('errorGeneric');
  String get errorNetwork => _t('errorNetwork');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get confirmDelete => _t('confirmDelete');
  String get confirmDeleteDesc => _t('confirmDeleteDesc');
  String get selfieRequired => _t('selfieRequired');

  // Profile setup
  String get profileSetupSubtitle => _t('profileSetupSubtitle');
  String get profileImportanceWarning => _t('profileImportanceWarning');
  String get profileNameRequired => _t('profileNameRequired');
  String get profileNameTooShort => _t('profileNameTooShort');
  String get profileDobLabel => _t('profileDobLabel');
  String get profileDobRequired => _t('profileDobRequired');
  String get profileGenderLabel => _t('profileGenderLabel');
  String get profileGenderMale => _t('profileGenderMale');
  String get profileGenderFemale => _t('profileGenderFemale');
  String get profileGenderOther => _t('profileGenderOther');
  String get profileGenderRequired => _t('profileGenderRequired');
  String get profileNationalIdLabel => _t('profileNationalIdLabel');
  String get profileNationalIdHelper => _t('profileNationalIdHelper');
  String get profileNationalIdRequired => _t('profileNationalIdRequired');
  String get profileCityLabel => _t('profileCityLabel');
  String get profileCityRequired => _t('profileCityRequired');
  String get profileRegionLabel => _t('profileRegionLabel');
  String get profileAddressLabel => _t('profileAddressLabel');
  String get profileAddressRequired => _t('profileAddressRequired');

  // Profile incomplete gate
  String get profileIncompleteTitle => _t('profileIncompleteTitle');
  String get profileIncompleteDesc => _t('profileIncompleteDesc');
  String get profileCompleteNow => _t('profileCompleteNow');

  // Support
  String get supportTitle => _t('supportTitle');
  String get supportFaqTitle => _t('supportFaqTitle');
  String get supportFaq1Q => _t('supportFaq1Q');
  String get supportFaq1A => _t('supportFaq1A');
  String get supportFaq2Q => _t('supportFaq2Q');
  String get supportFaq2A => _t('supportFaq2A');
  String get supportFaq3Q => _t('supportFaq3Q');
  String get supportFaq3A => _t('supportFaq3A');
  String get supportContactTitle => _t('supportContactTitle');
  String get supportContactEmail => _t('supportContactEmail');
  String get supportContactDesc => _t('supportContactDesc');
  String get supportSendEmail => _t('supportSendEmail');

  // Guided tour
  String get tourSkip => _t('tourSkip');
  String get tourNext => _t('tourNext');
  String get tourDone => _t('tourDone');
  String get tourStep1Title => _t('tourStep1Title');
  String get tourStep1Body => _t('tourStep1Body');
  String get tourStep2Title => _t('tourStep2Title');
  String get tourStep2Body => _t('tourStep2Body');
  String get tourStep3Title => _t('tourStep3Title');
  String get tourStep3Body => _t('tourStep3Body');
  String get tourStep4Title => _t('tourStep4Title');
  String get tourStep4Body => _t('tourStep4Body');
  String get tourStep5Title => _t('tourStep5Title');
  String get tourStep5Body => _t('tourStep5Body');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
