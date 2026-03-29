// ============================================================
//  friends_provider.dart
//  Gerencia lista de amigos, convites e conexões.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/invite_model.dart';
import '../models/connection_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class FriendsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  String? _userId;
  List<UserModel> _friends = [];
  String? _myInviteCode;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  StreamSubscription<ConnectionModel?>? _connectionsSub;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<UserModel> get friends => List.unmodifiable(_friends);
  List<String> get friendIds => _friends.map((f) => f.id).toList();
  String? get myInviteCode => _myInviteCode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // ── Inicialização ─────────────────────────────────────────────────────────

  void initialize(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _listenToConnections();
  }

  void _listenToConnections() {
    _connectionsSub?.cancel();
    _connectionsSub = _firestoreService
        .connectionsStream(_userId!)
        .listen(
          (conn) async {
            if (conn == null) return;
            await _loadFriendProfiles(conn.amigos);
          },
          onError: (e) => _setError('Erro ao carregar amigos: $e'),
        );
  }

  Future<void> _loadFriendProfiles(List<String> ids) async {
    if (ids.isEmpty) {
      _friends = [];
      notifyListeners();
      return;
    }
    try {
      _friends = await _firestoreService.getUsersByIds(ids);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao buscar perfis: $e');
    }
  }

  // ── Convites ──────────────────────────────────────────────────────────────

  /// Gera um código de convite único de 6 caracteres e salva no Firestore.
  Future<String?> generateInviteCode() async {
    if (_userId == null) return null;
    _setLoading(true);
    _clearMessages();
    try {
      // Gera código único em maiúsculas
      final raw = const Uuid().v4().replaceAll('-', '').toUpperCase();
      final code = raw.substring(0, AppConfig.inviteCodeLength);
      final invite = InviteModel(
        codigo: code,
        criadoPor: _userId!,
        criadoEm: DateTime.now(),
      );
      await _firestoreService.saveInvite(invite);
      _myInviteCode = code;
      notifyListeners();
      return code;
    } catch (e) {
      _setError('Erro ao gerar convite: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Valida e aceita um código de convite de outro usuário.
  Future<bool> joinWithCode(String code) async {
    if (_userId == null) return false;
    _setLoading(true);
    _clearMessages();
    try {
      final invite = await _firestoreService.getInvite(code.toUpperCase());

      if (invite == null || !invite.isValid) {
        _setError(AppStrings.errorInvalidCode);
        return false;
      }
      if (invite.criadoPor == _userId) {
        _setError(AppStrings.errorSelfInvite);
        return false;
      }
      if (_friends.any((f) => f.id == invite.criadoPor)) {
        _setError(AppStrings.errorAlreadyFriends);
        return false;
      }
      // Cria vínculo bidirecional e remove o convite
      await _firestoreService.acceptInvite(
        currentUserId: _userId!,
        inviteOwnerId: invite.criadoPor,
        inviteCodigo: invite.codigo,
      );
      _successMessage = AppStrings.successFriendAdded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao aceitar convite: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove um amigo (vínculo bidirecional).
  Future<void> removeFriend(String friendId) async {
    if (_userId == null) return;
    _setLoading(true);
    try {
      await _firestoreService.removeFriend(_userId!, friendId);
    } catch (e) {
      _setError('Erro ao remover amigo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    _connectionsSub?.cancel();
    _userId = null;
    _friends = [];
    _myInviteCode = null;
    _isLoading = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Privado ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _successMessage = null;
  }

  void clearMessages() {
    _clearMessages();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionsSub?.cancel();
    super.dispose();
  }
}

