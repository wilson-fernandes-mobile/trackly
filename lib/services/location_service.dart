// ============================================================
//  location_service.dart
//  Serviço de GPS que abstrai o geolocator.
// ============================================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ── Permissões ───────────────────────────────────────────────────────────

  /// Verifica e solicita permissões de localização.
  /// Retorna true se a permissão foi concedida.
  /// Não abre configurações automaticamente para não navegar fora do app.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false; // GPS desligado — não abre settings

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Verifica (sem pedir) se a permissão já está concedida.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ── Posição atual ────────────────────────────────────────────────────────

  /// Retorna a posição atual com timeout de 10 segundos para não travar o app.
  Future<Position?> getCurrentPosition() async {
    final hasPerms = await hasPermission();
    if (!hasPerms) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // mais rápido que high
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => Geolocator.getLastKnownPosition().then(
          (p) => p ?? Future.error('GPS timeout'),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition erro: $e');
      return Geolocator.getLastKnownPosition();
    }
  }

  // ── Stream de posição ─────────────────────────────────────────────────────

  /// Retorna um stream contínuo de atualizações de posição.
  /// Use [distanceFilter] para evitar updates desnecessários.
  /// Stream de posição com suporte a background (foreground service no Android,
  /// background mode no iOS). Continua rodando com o app minimizado.
  Stream<Position> getPositionStream({int distanceFilter = 10}) {
    late LocationSettings settings;

    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: distanceFilter,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Trackly',
          notificationText: 'Compartilhando sua localização...',
          enableWakeLock: true,
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        ),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: distanceFilter,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: distanceFilter,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  // ── Cálculo de distância ──────────────────────────────────────────────────

  /// Calcula a distância em metros entre dois pontos.
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

