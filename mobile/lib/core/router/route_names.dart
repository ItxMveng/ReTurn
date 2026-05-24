/// Noms de routes utilisés dans toute l'application
abstract final class RouteNames {
  // ── Onboarding / Auth ────────────────────────────────────────────────────
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const register = 'register';
  static const otpVerify = 'otp-verify';

  // ── Shell principal (BottomNav) ──────────────────────────────────────────
  static const home = 'home';
  static const declarations = 'declarations';
  static const matches = 'matches';
  static const messages = 'messages';
  static const profile = 'profile';

  // ── Déclarations ─────────────────────────────────────────────────────────
  static const declarationNew = 'declaration-new';
  static const declarationDetail = 'declaration-detail';
  static const declarationEdit = 'declaration-edit';

  // ── Matchs ───────────────────────────────────────────────────────────────
  static const matchDetail = 'match-detail';

  // ── Messagerie ───────────────────────────────────────────────────────────
  static const conversation = 'conversation';

  // ── Restitution ──────────────────────────────────────────────────────────
  static const restitutionFlow = 'restitution-flow';
  static const restitutionConfirm = 'restitution-confirm';
  static const restitutionSuccess = 'restitution-success';

  // ── Profil ───────────────────────────────────────────────────────────────
  static const profileEdit = 'profile-edit';
  static const settings = 'settings';
  static const notifications = 'notifications';
}

/// Chemins de routes
abstract final class RoutePaths {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const otpVerify = '/auth/otp';

  static const home = '/home';
  static const declarations = '/declarations';
  static const matches = '/matches';
  static const messages = '/messages';
  static const profile = '/profile';

  static const declarationNew = '/declarations/new';
  static const declarationDetail = '/declarations/:id';
  static const declarationEdit = '/declarations/:id/edit';

  static const matchDetail = '/matches/:id';

  static const conversation = '/messages/:matchId';

  static const restitutionFlow = '/restitution/:matchId';
  static const restitutionConfirm = '/restitution/:matchId/confirm';
  static const restitutionSuccess = '/restitution/success';

  static const profileEdit = '/profile/edit';
  static const settings = '/settings';
  static const notifications = '/notifications';
}
