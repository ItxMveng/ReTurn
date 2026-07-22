import 'dart:io';
import 'package:dio/dio.dart';
import '../models/ocr_result.dart';

/// Appelle l'endpoint backend `POST /ocr/extract` qui proxifie Mistral Vision.
///
/// Avantages vs Mistral appelé directement depuis l'app :
///   • la clé API reste côté serveur (jamais dans l'APK) ;
///   • l'IA lit aussi bien l'imprimé que le manuscrit (actes de naissance) ;
///   • requête authentifiée via l'intercepteur JWT du [Dio] partagé.
class BackendOcrService {
  final Dio _dio;
  BackendOcrService(this._dio);

  /// Retourne un [OcrResult] si l'IA a traité l'image, `null` si l'IA est
  /// indisponible côté serveur (l'app bascule alors sur ML Kit local).
  Future<OcrResult?> extract(File image) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split(Platform.pathSeparator).last,
      ),
    });

    final res = await _dio.post<Map<String, dynamic>>(
      '/ocr/extract',
      data: form,
    );
    final data = res.data;
    if (data == null || data['used_ai'] != true) return null;

    return OcrResult(
      rawText: (data['raw_text'] as String?) ?? '',
      documentNumber: _str(data['numero']),
      lastName: _str(data['nom']),
      firstName: _str(data['prenom']),
      birthDate: _str(data['date_naissance']),
      expiryDate: _str(data['date_expiration']),
      mrz: null,
      kind: _parseKind(_str(data['type_document'])),
    );
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  DocumentKind _parseKind(String? s) => switch (s?.toUpperCase()) {
        'CNI' => DocumentKind.cni,
        'PASSEPORT' => DocumentKind.passport,
        'VISA' => DocumentKind.passport,
        'PERMIS' => DocumentKind.driverLicense,
        'ACTE_NAISSANCE' => DocumentKind.birthCertificate,
        'CARTE_GRISE' => DocumentKind.vehicleRegistration,
        'DIPLOME' => DocumentKind.diploma,
        _ => DocumentKind.unknown,
      };
}
