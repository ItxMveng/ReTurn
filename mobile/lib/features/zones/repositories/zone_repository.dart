import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// Zone de récupération certifiée (F-32) : commissariat, mairie, campus…
class Zone {
  final String id;
  final String name;
  final String zoneType;
  final String address;
  final double latitude;
  final double longitude;
  final bool isCertified;

  const Zone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isCertified,
  });

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        zoneType: j['zone_type'] as String? ?? '',
        address: j['address'] as String? ?? '',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        isCertified: j['is_certified'] as bool? ?? true,
      );

  String get typeLabel => switch (zoneType) {
        'police' || 'commissariat' => 'Commissariat',
        'mairie' || 'city_hall' => 'Mairie',
        'campus' || 'university' => 'Campus',
        _ => zoneType.isEmpty ? 'Point certifié' : zoneType,
      };
}

class ZoneRepository {
  final Dio _dio;
  ZoneRepository(this._dio);

  Future<List<Zone>> list() async {
    final res = await _dio.get('/zones/');
    final items = res.data as List;
    return items
        .map((e) => Zone.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final zoneRepositoryProvider =
    Provider<ZoneRepository>((ref) => ZoneRepository(ref.read(dioProvider)));

final zonesProvider = FutureProvider<List<Zone>>((ref) async {
  return ref.read(zoneRepositoryProvider).list();
});
