// ============================================================
//  invite_model.dart
//  Representa um convite gerado por um usuário.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class InviteModel {
  final String codigo;
  final String criadoPor;
  final DateTime criadoEm;

  const InviteModel({
    required this.codigo,
    required this.criadoPor,
    required this.criadoEm,
  });

  // ── Firestore ↔ Model ─────────────────────────────────────────────────────

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      codigo: map[InviteFields.codigo] as String? ?? '',
      criadoPor: map[InviteFields.criadoPor] as String? ?? '',
      criadoEm: map[InviteFields.criadoEm] != null
          ? (map[InviteFields.criadoEm] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      InviteFields.codigo: codigo,
      InviteFields.criadoPor: criadoPor,
      InviteFields.criadoEm: Timestamp.fromDate(criadoEm),
    };
  }

  /// Verifica se o convite ainda é válido (menos de 48 horas)
  bool get isValid {
    final expiresAt = criadoEm.add(
      const Duration(hours: AppConfig.inviteExpirationHours),
    );
    return DateTime.now().isBefore(expiresAt);
  }

  @override
  String toString() =>
      'InviteModel(codigo: $codigo, criadoPor: $criadoPor, criadoEm: $criadoEm)';
}

