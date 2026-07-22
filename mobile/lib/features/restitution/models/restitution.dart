class Restitution {
  final String id;
  final String matchId;
  final String? meetingLocation;
  final List<String> proofPhotos;
  final String status; // pending | in_progress | completed | cancelled
  final bool handoffConfirmedByOwner;
  final bool handoffConfirmedByFinder;
  final int? ratingByOwner;
  final int? ratingByFinder;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const Restitution({
    required this.id,
    required this.matchId,
    this.meetingLocation,
    this.proofPhotos = const [],
    required this.status,
    this.handoffConfirmedByOwner = false,
    this.handoffConfirmedByFinder = false,
    this.ratingByOwner,
    this.ratingByFinder,
    this.completedAt,
    this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get bothConfirmed =>
      handoffConfirmedByOwner && handoffConfirmedByFinder;

  factory Restitution.fromJson(Map<String, dynamic> j) => Restitution(
        id: j['id'] as String,
        matchId: j['match_id'] as String,
        meetingLocation: j['meeting_location'] as String?,
        proofPhotos:
            (j['proof_photos'] as List?)?.cast<String>() ?? const [],
        status: j['status'] as String? ?? 'pending',
        handoffConfirmedByOwner: (j['handoff_confirmed_by_owner'] ??
            j['confirmed_by_owner']) as bool? ??
            false,
        handoffConfirmedByFinder: (j['handoff_confirmed_by_finder'] ??
            j['confirmed_by_finder']) as bool? ??
            false,
        ratingByOwner: j['rating_by_owner'] as int?,
        ratingByFinder: j['rating_by_finder'] as int?,
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String)
            : null,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
