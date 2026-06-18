/// Constantes de noms de routes — utiliser ces constantes
/// dans tous les appels pushNamed / goNamed pour éviter les typos.
class RouteNames {
  RouteNames._();

  // Auth
  static const splash     = 'splash';
  static const login      = 'login';
  static const register   = 'register';
  static const otpVerify  = 'otp-verify';

  // Shell principal
  static const home            = 'home';
  static const declarations    = 'declarations';
  static const newDeclaration  = 'new-declaration';
  static const declarationDetail = 'declaration-detail';
  static const matches         = 'matches';
  static const matchDetail     = 'match-detail';
  static const restitutionDetail = 'restitution-detail';
  static const messaging       = 'messaging';
  static const conversation    = 'conversation';
  static const profile         = 'profile';
  static const editProfile     = 'edit-profile';
}

/// Chemins de routes (utilisés dans GoRouter et ScaffoldShell)
class RoutePaths {
  RoutePaths._();

  static const home         = '/declarations';
  static const declarations = '/declarations';
  static const matches      = '/matches';
  static const messages     = '/messages';
  static const profile      = '/profile';
}
