// ============================================================
//  friends_screen.dart
//  Tela de amigos: gerar convite, aceitar código, listar amigos.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/friends_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Amigos',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.qr_code), text: 'Meu Código'),
              Tab(icon: Icon(Icons.person_add_alt_1), text: 'Entrar'),
              Tab(icon: Icon(Icons.people), text: 'Amigos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyCodeTab(),
            _JoinTab(),
            _FriendsListTab(),
          ],
        ),
      ),
    );
  }
}

// ── Aba 1: Meu Código ──────────────────────────────────────────────────────────

class _MyCodeTab extends StatelessWidget {
  const _MyCodeTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FriendsProvider>();

    return LoadingOverlay(
      isLoading: prov.isLoading,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share_location, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Compartilhe este código com um amigo\npara conectar suas localizações.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            if (prov.myInviteCode != null) ...[
              _CodeDisplay(code: prov.myInviteCode!),
              const SizedBox(height: 16),
              const Text(
                'Válido por 48 horas',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
            CustomButton(
              label: prov.myInviteCode == null ? 'Gerar código' : 'Novo código',
              icon: Icons.refresh,
              isLoading: prov.isLoading,
              onPressed: () => prov.generateInviteCode(),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget que mostra o código com botão de cópia
class _CodeDisplay extends StatelessWidget {
  final String code;
  const _CodeDisplay({required this.code});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código copiado!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.copy, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Aba 2: Entrar com Código ───────────────────────────────────────────────────

class _JoinTab extends StatefulWidget {
  const _JoinTab();

  @override
  State<_JoinTab> createState() => _JoinTabState();
}

class _JoinTabState extends State<_JoinTab> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<FriendsProvider>();
    prov.clearMessages();
    final ok = await prov.joinWithCode(_codeController.text.trim());
    if (!mounted) return;
    if (ok) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.successMessage ?? AppStrings.successFriendAdded),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? AppStrings.errorGeneric),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FriendsProvider>();
    return LoadingOverlay(
      isLoading: prov.isLoading,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Digite o código de 6 caracteres\ncompartilhado por um amigo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: AppConfig.inviteCodeLength,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Código do amigo',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.surface,
                  counterStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().length != AppConfig.inviteCodeLength) {
                    return 'O código deve ter ${AppConfig.inviteCodeLength} caracteres.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Conectar',
              icon: Icons.link,
              isLoading: prov.isLoading,
              onPressed: _join,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aba 3: Lista de Amigos ─────────────────────────────────────────────────────

class _FriendsListTab extends StatelessWidget {
  const _FriendsListTab();

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendsProvider>().friends;

    if (friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Nenhum amigo conectado ainda.\nGere um código na aba "Meu Código".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (ctx, i) => _FriendTile(friend: friends[i]),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final UserModel friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            friend.nome.isNotEmpty ? friend.nome[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(friend.nome,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(friend.email,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador online/offline
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: friend.online ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Botão remover amigo
            IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.red),
              tooltip: 'Remover amigo',
              onPressed: () => _confirmRemove(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remover amigo',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remover ${friend.nome}?\nVocê não verá mais a localização um do outro.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Remover',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              context.read<FriendsProvider>().removeFriend(friend.id);
            },
          ),
        ],
      ),
    );
  }
}

