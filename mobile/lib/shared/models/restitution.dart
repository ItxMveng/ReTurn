/// Modèle Restitution — correspond au schéma backend RestitutionOut
/// Cycle : requested → verified → completed | disputed | cancelled
class Restitution {
  final String id;
  final String matchId;
  final String requesterId;  // user qui demande la restitution
  final String holderId;     // user qui détient le document
  final String status;       // requested | verified | completed | disputed | cancelled
  final double? holderRating;
  final double? requesterRating;
  final String? meetingLocation;
  final DateTime? meetingScheduledAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Restitution({
    required this.id,
    required this.matchId,
    required this.requesterId,
    required this.holderId,
    required this.status,
    this.holderRating,
    this.requesterRating,
    this.meetingLocation,
    this.meetingScheduledAt,
    this.completedAt,
    required this.createdAt,
  });

  factory Restitution.fromJson(Map<String, dynamic> json) => Restitution(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        requesterId: json['requester_id'] as String,
        holderId: json['holder_id'] as String,
        status: json['status'] as String,
        holderRating: (json['holder_rating'] as num?)?.toDouble(),
        requesterRating: (json['requester_rating'] as num?)?.toDouble(),
        meetingLocation: json['meeting_location'] as String?,
        meetingScheduledAt: json['meeting_scheduled_at'] != null
            ? DateTime.parse(json['meeting_scheduled_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'match_id': matchId,
        'requester_id': requesterId,
        'holder_id': holderId,
        'status': status,
        if (holderRating != null) 'holder_rating': holderRating,
        if (requesterRating != null) 'requester_rating': requesterRating,
        if (meetingLocation != null) 'meeting_location': meetingLocation,
        if (meetingScheduledAt != null)
          'meeting_scheduled_at': meetingScheduledAt!.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get isRequested  => status == 'requested';
  bool get isVerified   => status == 'verified';
  bool get isCompleted  => status == 'completed';
  bool get isDisputed   => status == 'disputed';
  bool get isCancelled  => status == 'cancelled';
  bool get isActive     => isRequested || isVerified;

  bool isRequester(String userId) => requesterId == userId;
  bool isHolder(String userId)    => holderId == userId;

  bool canRate(String userId) =>
      isCompleted &&
      ((isRequester(userId) && holderRating == null) ||
       (isHolder(userId) && requesterRating == null));

  String get statusLabel => switch (status) {
        'requested'  => 'Demandée',
        'verified'   => 'Identité vérifiée',
        'completed'  => 'Complétée',
        'disputed'   => 'Litigieuse',
        'cancelled'  => 'Annulée',
        _            => status,
      };
}
