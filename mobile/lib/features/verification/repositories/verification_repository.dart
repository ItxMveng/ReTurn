import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// Accès à la vérification d'identité adaptative (F-30) d'un match.
class VerificationRepository {
  final Dio _dio;
  VerificationRepository(this._dio);

  /// Statut courant (null si aucune vérification n'a été commencée).
  Future<Map<String, dynamic>?> status(String matchId) async {
    final res = await _dio.get('/messaging/$matchId/verify');
    final data = res.data;
    return data is Map ? data.cast<String, dynamic>() : null;
  }

  /// Démarre (ou récupère) la demande de vérification. Le backend calcule le
  /// niveau exigé (1-3) à partir du score du match.
  Future<Map<String, dynamic>> start(String matchId) async {
    final res = await _dio.post('/messaging/$matchId/verify');
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Score de confiance du match (détermine le niveau de vérification).
  Future<double?> matchScore(String matchId) async {
    final res = await _dio.get('/matches/$matchId');
    final data = res.data;
    if (data is Map) return (data['score'] as num?)?.toDouble();
    return null;
  }

  /// Questions de contrôle : nom + date de naissance (+ numéro au niveau 3).
  /// Lance [DioException] (400) si elles ne correspondent pas au document.
  Future<Map<String, dynamic>> submitAnswers(
    String matchId, {
    required String fullName,
    required String dateOfBirth, // format YYYY-MM-DD
    String? documentNumber,
  }) async {
    final res = await _dio.post('/messaging/$matchId/verify/answers', data: {
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      if (documentNumber != null && documentNumber.isNotEmpty)
        'document_number': documentNumber,
    });
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Envoi du selfie (approuve la vérification aux niveaux 1-2 si les
  /// questions sont validées ; au niveau 3 le dossier part en revue admin).
  Future<Map<String, dynamic>> submitSelfie(String matchId, File selfie) async {
    final form = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(selfie.path, filename: 'selfie.jpg'),
    });
    final res = await _dio.post(
      '/messaging/$matchId/verify/selfie',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Photo du document (niveau 3 uniquement) — jointe pour la revue admin.
  Future<Map<String, dynamic>> submitDocPhoto(String matchId, File photo) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photo.path, filename: 'document.jpg'),
    });
    final res = await _dio.post(
      '/messaging/$matchId/verify/doc_photo',
      data: form,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(ref.read(dioProvider)),
);
