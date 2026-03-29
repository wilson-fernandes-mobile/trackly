// ============================================================
//  connection_model.dart
//  Representa a lista de amigos (conexões) de um usuário.
//  Documento único por usuário na coleção "conexoes".
// ============================================================

import '../utils/constants.dart';

class ConnectionModel {
  final String userId;
  final List<String> amigos;

  const ConnectionModel({
    required this.userId,
    required this.amigos,
  });

  // ── Firestore ↔ Model ─────────────────────────────────────────────────────

  factory ConnectionModel.fromMap(Map<String, dynamic> map) {
    return ConnectionModel(
      userId: map[ConnectionFields.userId] as String? ?? '',
      amigos: List<String>.from(
        (map[ConnectionFields.amigos] as List<dynamic>?) ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ConnectionFields.userId: userId,
      ConnectionFields.amigos: amigos,
    };
  }

  // ── Utilitários ──────────────────────────────────────────────────────────

  /// Retorna uma cópia com um novo amigo adicionado (sem duplicatas)
  ConnectionModel withFriend(String friendId) {
    if (amigos.contains(friendId)) return this;
    return ConnectionModel(userId: userId, amigos: [...amigos, friendId]);
  }

  /// Retorna uma cópia sem o amigo especificado
  ConnectionModel withoutFriend(String friendId) {
    return ConnectionModel(
      userId: userId,
      amigos: amigos.where((id) => id != friendId).toList(),
    );
  }

  bool hasFriend(String friendId) => amigos.contains(friendId);

  @override
  String toString() =>
      'ConnectionModel(userId: $userId, amigos: ${amigos.length})';
}

