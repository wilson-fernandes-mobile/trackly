// ============================================================
//  location_model.dart
//  Representa a localização atual de um usuário.
//  Documento único por usuário na coleção "localizacoes".
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class LocationModel {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime atualizadoEm;

  const LocationModel({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.atualizadoEm,
  });

  // ── Firestore ↔ Model ─────────────────────────────────────────────────────

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      userId: map[LocationFields.userId] as String? ?? '',
      latitude: (map[LocationFields.latitude] as num?)?.toDouble() ?? 0.0,
      longitude: (map[LocationFields.longitude] as num?)?.toDouble() ?? 0.0,
      atualizadoEm: map[LocationFields.atualizadoEm] != null
          ? (map[LocationFields.atualizadoEm] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      LocationFields.userId: userId,
      LocationFields.latitude: latitude,
      LocationFields.longitude: longitude,
      LocationFields.atualizadoEm: FieldValue.serverTimestamp(),
    };
  }

  // ── Utilitários ──────────────────────────────────────────────────────────

  /// Verifica se a localização foi atualizada recentemente (menos de 5 minutos)
  bool get isRecent {
    return DateTime.now().difference(atualizadoEm).inMinutes < 5;
  }

  LocationModel copyWith({
    String? userId,
    double? latitude,
    double? longitude,
    DateTime? atualizadoEm,
  }) {
    return LocationModel(
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  @override
  String toString() =>
      'LocationModel(userId: $userId, lat: $latitude, lng: $longitude)';
}

