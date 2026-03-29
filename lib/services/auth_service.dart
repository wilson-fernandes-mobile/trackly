// ============================================================
//  auth_service.dart
//  Serviço de autenticação via Firebase Auth.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ── Stream de estado de autenticação ─────────────────────────────────────

  /// Emite o usuário atual sempre que o estado de login muda.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Retorna o usuário Firebase atualmente logado (pode ser null).
  User? get currentFirebaseUser => _auth.currentUser;

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Autentica com email e senha.
  /// Lança [FirebaseAuthException] em caso de erro.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user == null) return null;
    return _firestoreService.getUser(credential.user!.uid);
  }

  // ── Cadastro ──────────────────────────────────────────────────────────────

  /// Cria uma conta e salva o perfil no Firestore.
  /// Lança [FirebaseAuthException] em caso de erro.
  Future<UserModel?> signUp({
    required String nome,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user == null) return null;

    // Salvar perfil na coleção "users"
    final user = UserModel(
      id: credential.user!.uid,
      nome: nome.trim(),
      email: email.trim(),
    );
    await _firestoreService.createUser(user);

    // Criar documento de conexões vazio
    await _firestoreService.initializeConnections(credential.user!.uid);

    return user;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Encerra a sessão e marca usuário como offline no Firestore.
  Future<void> signOut(String userId) async {
    await _firestoreService.setOnlineStatus(userId, isOnline: false);
    await _auth.signOut();
  }

  // ── Perfil ────────────────────────────────────────────────────────────────

  /// Busca o perfil do usuário no Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    return _firestoreService.getUser(uid);
  }

  // ── Tratamento de erros ───────────────────────────────────────────────────

  /// Converte o código de erro do Firebase em mensagem legível em português.
  static String translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Usuário desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return 'Erro: ${e.message ?? e.code}';
    }
  }
}

