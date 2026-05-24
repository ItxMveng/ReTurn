class Match {
  const Match({
    required this.id,
    required this.documentType,
    required this.score,
    required this.status,
    required this.foundDeclarationId,
    required this.lostDeclarationId,
    this.confirmedAt,
  });

  final String id;
  final String documentType;
  final double score;
  final String status;
  final String foundDeclarationId;
  final String lostDeclarationId;
  final DateTime? confirmedAt;

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id'] as String,
        documentType: json['document_type'] as String? ?? 'Document',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] as String? ?? 'pending',
        foundDeclarationId: json['found_declaration_id'] as String,
        lostDeclarationId: json['lost_declaration_id'] as String,
        confirmedAt: json['confirmed_at'] != null
            ? DateTime.tryParse(json['confirmed_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'document_type': documentType,
        'score': score,
        'status': status,
        'found_declaration_id': foundDeclarationId,
        'lost_declaration_id': lostDeclarationId,
        if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
      };
}
