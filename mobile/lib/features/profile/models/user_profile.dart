class UserProfile {
  final String id;
  final String nom;
  final String prenom;
  final String phone;
  final double reputation;
  final int declarationsCount;
  final int restitutionsCount;
  final DateTime memberSince;

  const UserProfile({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.phone,
    required this.reputation,
    required this.declarationsCount,
    required this.restitutionsCount,
    required this.memberSince,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        nom: j['nom'] as String,
        prenom: j['prenom'] as String,
        phone: j['phone'] as String,
        reputation: (j['reputation_score'] as num).toDouble(),
        declarationsCount: (j['declarations_count'] as int?) ?? 0,
        restitutionsCount: (j['restitutions_count'] as int?) ?? 0,
        memberSince: DateTime.parse(j['created_at'] as String),
      );

  String get fullName => '$prenom $nom';
  int get reputationPercent => (reputation * 100).clamp(0, 100).round();
}
