// ============================================================
//  constants.dart
//  Constantes globais do aplicativo Trackly.
// ============================================================

import 'package:flutter/material.dart';

// ── Coleções do Firestore ─────────────────────────────────────────────────────
class FirestoreCollections {
  FirestoreCollections._();
  static const String users = 'users';
  static const String invites = 'convites';
  static const String connections = 'conexoes';
  static const String locations = 'localizacoes';
}

// ── Campos dos documentos ─────────────────────────────────────────────────────
class UserFields {
  UserFields._();
  static const String id = 'id';
  static const String nome = 'nome';
  static const String email = 'email';
  static const String online = 'online';
  static const String ultimaVez = 'ultimaVez';
  static const String fotoPerfil = 'fotoPerfil'; // base64 da foto de perfil
}

class InviteFields {
  InviteFields._();
  static const String codigo = 'codigo';
  static const String criadoPor = 'criadoPor';
  static const String criadoEm = 'criadoEm';
}

class ConnectionFields {
  ConnectionFields._();
  static const String userId = 'userId';
  static const String amigos = 'amigos';
}

class LocationFields {
  LocationFields._();
  static const String userId = 'userId';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String atualizadoEm = 'atualizadoEm';
}

// ── Configurações ─────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  /// Intervalo de atualização da localização no Firestore (segundos)
  static const int locationUpdateIntervalSeconds = 4;

  /// Comprimento do código de convite
  static const int inviteCodeLength = 6;

  /// Tempo máximo que um convite permanece ativo (horas)
  static const int inviteExpirationHours = 48;

  /// Acurácia mínima GPS aceita (metros)
  static const double gpsAccuracyThreshold = 50.0;
}

// ── Cores do tema ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryDark = Color(0xFF158A3E);
  static const Color secondary = Color(0xFF0D47A1);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color error = Color(0xFFCF6679);
  static const Color online = Color(0xFF1DB954);
  static const Color offline = Color(0xFF757575);
}

// ── Strings de UI ─────────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();
  static const String appName = 'Trackly';
  static const String errorGeneric = 'Ocorreu um erro. Tente novamente.';
  static const String errorInvalidCode = 'Código de convite inválido.';
  static const String errorSelfInvite = 'Você não pode usar o seu próprio código.';
  static const String errorAlreadyFriends = 'Vocês já são amigos!';
  static const String successFriendAdded = 'Amigo adicionado com sucesso!';
  static const String locationPermissionDenied =
      'Permissão de localização negada. Ative nas configurações.';
}

