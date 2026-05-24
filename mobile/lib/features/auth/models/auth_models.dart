class LoginRequest {
  final String phone;
  final String password;
  LoginRequest({required this.phone, required this.password});
  Map<String, dynamic> toJson() =>
      {'phone': phone, 'password': password};
}

class RegisterRequest {
  final String phone;
  final String password;
  final String nom;
  final String prenom;
  RegisterRequest(
      {required this.phone,
      required this.password,
      required this.nom,
      required this.prenom});
  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
        'nom': nom,
        'prenom': prenom,
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  AuthTokens({required this.accessToken, required this.refreshToken});
  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
      );
}
