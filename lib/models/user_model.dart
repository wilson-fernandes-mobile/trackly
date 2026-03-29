// ============================================================
//  user_model.dart
//  Representa um usuário do Trackly.
// ============================================================

import '../utils/constants.dart';

class UserModel {
  final String id;
  final String nome;
  final String email;
  final bool online;
  final DateTime? ultimaVez;
  final String? fotoPerfil; // imagem base64 da foto de perfil

  const UserModel({
    required this.id,
    required this.nome,
    required this.email,
    this.online = false,
    this.ultimaVez,
    this.fotoPerfil,
  });

  // ── Firestore ↔ Model ─────────────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map[UserFields.id] as String? ?? '',
      nome: map[UserFields.nome] as String? ?? '',
      email: map[UserFields.email] as String? ?? '',
      online: map[UserFields.online] as bool? ?? false,
      ultimaVez: map[UserFields.ultimaVez] != null
          ? (map[UserFields.ultimaVez] as dynamic).toDate() as DateTime
          : null,
      fotoPerfil: map[UserFields.fotoPerfil] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      UserFields.id: id,
      UserFields.nome: nome,
      UserFields.email: email,
      UserFields.online: online,
      if (ultimaVez != null) UserFields.ultimaVez: ultimaVez,
      if (fotoPerfil != null) UserFields.fotoPerfil: fotoPerfil,
    };
  }

  // ── Cópia com campos alterados ────────────────────────────────────────────

  UserModel copyWith({
    String? id,
    String? nome,
    String? email,
    bool? online,
    DateTime? ultimaVez,
    String? fotoPerfil,
  }) {
    return UserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      online: online ?? this.online,
      ultimaVez: ultimaVez ?? this.ultimaVez,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, nome: $nome, email: $email)';
}

