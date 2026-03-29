// ============================================================
//  firestore_service.dart
//  Serviço central de acesso ao Cloud Firestore.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/invite_model.dart';
import '../models/connection_model.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Referências ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection(FirestoreCollections.invites);
  CollectionReference<Map<String, dynamic>> get _connections =>
      _db.collection(FirestoreCollections.connections);
  CollectionReference<Map<String, dynamic>> get _locations =>
      _db.collection(FirestoreCollections.locations);

  // ── USERS ─────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Salva a foto de perfil como base64 no documento do usuário.
  Future<void> updateUserPhoto(String userId, String base64Photo) async {
    await _users.doc(userId).update({UserFields.fotoPerfil: base64Photo});
  }

  Future<void> setOnlineStatus(String userId, {required bool isOnline}) async {
    await _users.doc(userId).update({
      UserFields.online: isOnline,
      UserFields.ultimaVez: FieldValue.serverTimestamp(),
    });
  }

  // ── CONEXÕES ─────────────────────────────────────────────────────────────

  /// Inicializa o documento de conexões de um novo usuário (lista vazia).
  Future<void> initializeConnections(String userId) async {
    final model = ConnectionModel(userId: userId, amigos: []);
    await _connections.doc(userId).set(model.toMap());
  }

  /// Stream que emite a lista de amigos sempre que ela muda.
  Stream<ConnectionModel?> connectionsStream(String userId) {
    return _connections.doc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ConnectionModel.fromMap(snap.data()!);
    });
  }

  /// Busca os perfis de uma lista de userIds.
  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn suporta até 30 itens — fragmentar se necessário
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 30) {
      chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
    }
    final results = <UserModel>[];
    for (final chunk in chunks) {
      final snap = await _users.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snap.docs.map((d) => UserModel.fromMap(d.data())));
    }
    return results;
  }

  // ── CONVITES ─────────────────────────────────────────────────────────────

  Future<void> saveInvite(InviteModel invite) async {
    await _invites.doc(invite.codigo).set(invite.toMap());
  }

  Future<InviteModel?> getInvite(String codigo) async {
    final doc = await _invites.doc(codigo.toUpperCase()).get();
    if (!doc.exists || doc.data() == null) return null;
    return InviteModel.fromMap(doc.data()!);
  }

  Future<void> deleteInvite(String codigo) async {
    await _invites.doc(codigo).delete();
  }

  /// Cria vínculo bidirecional entre dois usuários e remove o convite.
  Future<void> acceptInvite({
    required String currentUserId,
    required String inviteOwnerId,
    required String inviteCodigo,
  }) async {
    final batch = _db.batch();
    // Adiciona um ao outro nas listas de amigos
    batch.update(_connections.doc(currentUserId), {
      ConnectionFields.amigos: FieldValue.arrayUnion([inviteOwnerId]),
    });
    batch.update(_connections.doc(inviteOwnerId), {
      ConnectionFields.amigos: FieldValue.arrayUnion([currentUserId]),
    });
    // Remove o convite usado
    batch.delete(_invites.doc(inviteCodigo));
    await batch.commit();
  }

  /// Remove amizade bidirecional.
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _db.batch();
    batch.update(_connections.doc(userId), {
      ConnectionFields.amigos: FieldValue.arrayRemove([friendId]),
    });
    batch.update(_connections.doc(friendId), {
      ConnectionFields.amigos: FieldValue.arrayRemove([userId]),
    });
    await batch.commit();
  }

  // ── LOCALIZAÇÃO ───────────────────────────────────────────────────────────

  /// Busca a última localização conhecida de um usuário (leitura única).
  Future<LocationModel?> getLocation(String userId) async {
    final doc = await _locations.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LocationModel.fromMap(doc.data()!);
  }

  Future<void> updateLocation(LocationModel location) async {
    await _locations.doc(location.userId).set(location.toMap());
  }

  Future<void> deleteLocation(String userId) async {
    await _locations.doc(userId).delete();
  }

  /// Stream da localização de um único usuário.
  Stream<LocationModel?> locationStream(String userId) {
    return _locations.doc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return LocationModel.fromMap(snap.data()!);
    });
  }
}

