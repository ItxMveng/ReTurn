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
      'tourSkip': 'Passer la visite',
      'tourNext': 'Suivant',
      'tourDone': 'Commencer !',
      'tourStep1Title': 'Page d\'accueil',
      'tourStep1Body': 'C\'est votre tableau de bord principal. Depuis ici, déclarez un document trouvé ou perdu.',
      'tourStep2Title': 'Déclarer un document trouvé',
      'tourStep2Body': 'Photographiez le document trouvé et renseignez les détails. L\'OCR remplit automatiquement les champs.',
      'tourStep3Title': 'Déclarer un document perdu',
      'tourStep3Body': 'Signalez la perte d\'un de vos documents. Vous serez notifié dès qu\'un match est trouvé.',
      'tourStep4Title': 'Mes déclarations',
      'tourStep4Body': 'Consultez et gérez toutes vos déclarations actives et passées.',
      'tourStep5Title': 'Mes matches',
      'tourStep5Body': 'Lorsqu\'un document trouvé correspond à un perdu, un match est créé ici. Confirmez-le pour démarrer la restitution.',
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
      'splashTagline': 'Réunissez documents & propriétaires',
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
      'tourSkip': 'Skip tour',
      'tourNext': 'Next',
      'tourDone': 'Get started!',
      'tourStep1Title': 'Home',
      'tourStep1Body': 'This is your main dashboard. From here, declare a found or lost document.',
      'tourStep2Title': 'Declare a found document',
      'tourStep2Body': 'Photograph the found document and enter the details. OCR automatically fills the fields.',
      'tourStep3Title': 'Declare a lost document',
      'tourStep3Body': 'Report one of your lost documents. You will be notified when a match is found.',
      'tourStep4Title': 'My declarations',
      'tourStep4Body': 'View and manage all your active and past declarations.',
      'tourStep5Title': 'My matches',
      'tourStep5Body': 'When a found document matches a lost one, a match is created here. Confirm it to start the handover.',
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
      'splashTagline': 'Connecting documents & owners',
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
    },
  };

  String _t(String key) {
    final lang = locale.languageCode;
    return _strings[lang]?[key] ?? _strings['fr']?[key] ?? key;
  }

  String get appName => _t('appName');
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
