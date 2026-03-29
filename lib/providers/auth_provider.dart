// ============================================================
//  auth_provider.dart
//  Gerencia o estado de autenticação do usuário logado.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // ── Inicialização ─────────────────────────────────────────────────────────

  AuthProvider() {
    // Escuta mudanças de estado de autenticação automaticamente
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    // Usuário logado → buscar perfil no Firestore
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getUserProfile(firebaseUser.uid);
      // Marcar online
      if (_currentUser != null) {
        // Status de online é atualizado via FirestoreService
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signIn(email: email, password: password);
      _currentUser = user;
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.translateError(e);
      return false;
    } catch (e) {
      _error = 'Erro inesperado. Tente novamente.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Cadastro ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String nome,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signUp(
        nome: nome,
        email: email,
        password: password,
      );
      _currentUser = user;
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.translateError(e);
      return false;
    } catch (e) {
      _error = 'Erro inesperado. Tente novamente.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    if (_currentUser == null) return;
    try {
      await _authService.signOut(_currentUser!.id);
    } finally {
      _currentUser = null;
      notifyListeners();
    }
  }

  // ── Privado ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Atualiza a foto de perfil do usuário localmente (após salvar no Firestore).
  void updateCurrentUserPhoto(String base64Photo) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(fotoPerfil: base64Photo);
    notifyListeners();
  }
}

