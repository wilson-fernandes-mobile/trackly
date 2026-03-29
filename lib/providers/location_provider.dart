// ============================================================
//  location_provider.dart
//  Gerencia localização do usuário e dos amigos via Firestore streams.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _userId;
  Position? _myPosition;
  bool _isSharing = false;
  bool _hasPermission = false;
  String? _error;

  /// Mapa userId → localização mais recente do amigo
  final Map<String, LocationModel> _friendsLocations = {};
  StreamSubscription<Position>? _positionSub;
  Timer? _firestoreUpdateTimer;
  final Map<String, StreamSubscription<LocationModel?>> _friendSubs = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  Position? get myPosition => _myPosition;
  bool get isSharing => _isSharing;
  bool get hasPermission => _hasPermission;
  String? get error => _error;
  Map<String, LocationModel> get friendsLocations =>
      Map.unmodifiable(_friendsLocations);

  // ── Inicialização ─────────────────────────────────────────────────────────

  /// Inicializa o provider: pede permissão e carrega a última posição conhecida
  /// do Firestore para mostrar no mapa imediatamente. NÃO inicia rastreamento.
  Future<void> initialize(String userId) async {
    if (_userId == userId) return; // já inicializado para este usuário
    _userId = userId;

    // Pede permissão (necessário para o ponto azul do mapa aparecer)
    _hasPermission = await _locationService.requestPermission();

    // Carrega última posição salva no Firestore para mostrar no mapa
    final lastLocation = await _firestoreService.getLocation(userId);
    if (lastLocation != null) {
      // Cria uma Position fake apenas para centralizar o mapa
      _myPosition = Position(
        latitude: lastLocation.latitude,
        longitude: lastLocation.longitude,
        timestamp: lastLocation.atualizadoEm,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    notifyListeners();
  }

  /// Solicita permissão explicitamente (chamado ao apertar "Compartilhar").
  Future<void> _checkPermission() async {
    _hasPermission = await _locationService.requestPermission();
    notifyListeners();
  }

  // ── Rastreamento próprio ──────────────────────────────────────────────────

  Future<void> _startTracking() async {
    _isSharing = true;
    notifyListeners();

    // Posição inicial imediata
    final initial = await _locationService.getCurrentPosition();
    if (initial != null) {
      _myPosition = initial;
      await _pushToFirestore(initial);
      notifyListeners();
    }

    // Stream contínuo de GPS → atualiza o estado local
    _positionSub = _locationService.getPositionStream().listen(
      (pos) async {
        _myPosition = pos;
        notifyListeners();
      },
      onError: (e) => _setError('Erro de GPS: $e'),
    );

    // Timer periódico → persiste no Firestore a cada X segundos
    _firestoreUpdateTimer = Timer.periodic(
      Duration(seconds: AppConfig.locationUpdateIntervalSeconds),
      (_) async {
        if (_myPosition != null && _isSharing) {
          await _pushToFirestore(_myPosition!);
        }
      },
    );
  }

  Future<void> _pushToFirestore(Position pos) async {
    if (_userId == null) return;
    final model = LocationModel(
      userId: _userId!,
      latitude: pos.latitude,
      longitude: pos.longitude,
      atualizadoEm: DateTime.now(),
    );
    try {
      await _firestoreService.updateLocation(model);
    } catch (e) {
      debugPrint('[LocationProvider] Erro ao atualizar localização: $e');
    }
  }

  // ── Controle de privacidade ───────────────────────────────────────────────

  Future<void> toggleSharing() async {
    if (_userId == null) return;
    if (_isSharing) {
      await stopSharing();
    } else {
      await _checkPermission();
      if (_hasPermission) await _startTracking();
    }
  }

  Future<void> stopSharing() async {
    _isSharing = false;
    _positionSub?.cancel();
    _firestoreUpdateTimer?.cancel();
    // NÃO deleta do Firestore — mantém a última posição conhecida
    // para amigos verem onde você estava mesmo quando parar de compartilhar
    notifyListeners();
  }

  // ── Amigos ────────────────────────────────────────────────────────────────

  /// Chamado pela HomeScreen quando a lista de amigos muda.
  void updateFriendIds(List<String> friendIds) {
    // Cancelar streams de amigos que não estão mais na lista
    final toRemove = _friendSubs.keys
        .where((id) => !friendIds.contains(id))
        .toList();
    for (final id in toRemove) {
      _friendSubs[id]?.cancel();
      _friendSubs.remove(id);
      _friendsLocations.remove(id);
    }
    // Adicionar streams para novos amigos
    for (final id in friendIds) {
      if (_friendSubs.containsKey(id)) continue;
      _friendSubs[id] = _firestoreService.locationStream(id).listen(
        (loc) {
          if (loc != null) {
            _friendsLocations[id] = loc;
          } else {
            _friendsLocations.remove(id);
          }
          notifyListeners();
        },
        onError: (e) => debugPrint('[LocationProvider] Erro amigo $id: $e'),
      );
    }
    notifyListeners();
  }

  // ── Limpeza ───────────────────────────────────────────────────────────────

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void reset() {
    _userId = null;
    _isSharing = false;
    _myPosition = null;
    _positionSub?.cancel();
    _firestoreUpdateTimer?.cancel();
    for (final sub in _friendSubs.values) {
      sub.cancel();
    }
    _friendSubs.clear();
    _friendsLocations.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

