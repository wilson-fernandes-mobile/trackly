// ============================================================
//  home_screen.dart
//  Tela principal: mapa com marcadores dos amigos + navegação.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/friends_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../friends/friends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  GoogleMapController? _mapController;
  bool _initialized = false;
  bool _hasCenteredOnPosition = false; // centraliza só uma vez por sessão
  bool _wasSharing = false;            // detecta transição parado → compartilhando

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<LocationProvider>().initialize(userId);
        context.read<FriendsProvider>().initialize(userId);
      }
    }
  }

  /// Move a câmera para a posição do usuário quando:
  /// 1) App abre e carrega última posição do Firestore
  /// 2) Usuário ativa "Compartilhar" e recebe o primeiro fix de GPS
  void _centerMapIfNeeded(Position? position, bool isSharing) {
    if (position == null || _mapController == null) return;

    final startedSharing = isSharing && !_wasSharing;
    _wasSharing = isSharing;

    if (!_hasCenteredOnPosition || startedSharing) {
      _hasCenteredOnPosition = true;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    }
  }

  // Sincroniza amigos com o LocationProvider quando mudam
  void _syncFriendLocations(List<String> friendIds) {
    context.read<LocationProvider>().updateFriendIds(friendIds);
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final friendIds = context.select<FriendsProvider, List<String>>(
      (f) => f.friendIds,
    );

    // Centraliza mapa na posição do usuário quando necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapIfNeeded(locationProv.myPosition, locationProv.isSharing);
      _syncFriendLocations(friendIds);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MapTab(onMapCreated: (c) => _mapController = c),
          const FriendsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Amigos',
          ),
        ],
      ),
    );
  }
}

// ── Aba do Mapa ────────────────────────────────────────────────────────────────

class _MapTab extends StatefulWidget {
  final void Function(GoogleMapController) onMapCreated;
  const _MapTab({required this.onMapCreated});

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  // Cache: userId → ícone circular já renderizado
  final Map<String, BitmapDescriptor> _iconCache = {};
  // Hash da foto usada para gerar o ícone (detecta mudança de foto)
  final Map<String, int> _iconPhotoHash = {};
  Set<Marker> _cachedMarkers = {};
  bool _refreshing = false;

  // ── Foto de perfil ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto(BuildContext ctx) async {
    // Capture what we need before any await
    final authProv = ctx.read<AuthProvider>();
    final userId = authProv.currentUser?.id;
    if (userId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);

    await FirestoreService().updateUserPhoto(userId, b64);
    authProv.updateCurrentUserPhoto(b64);
  }

  // ── Marcador circular ───────────────────────────────────────────────────────

  Future<BitmapDescriptor> _circularMarker(String b64, Color border) async {
    const size = 120;
    final bytes = base64Decode(b64);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(bytes),
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final src = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const radius = size / 2.0;
    const center = Offset(radius, radius);

    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawImage(src, Offset.zero, Paint()..isAntiAlias = true);
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = border
        ..strokeWidth = 4
        ..isAntiAlias = true,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  // ── Atualização assíncrona dos marcadores ───────────────────────────────────

  Future<void> _refreshMarkers(
    LocationProvider locProv,
    FriendsProvider friendsProv,
    UserModel? me,
  ) async {
    if (_refreshing) return;
    _refreshing = true;
    final markers = <Marker>{};

    // Marcador do usuário logado
    final myPos = locProv.myPosition;
    if (myPos != null) {
      final photo = me?.fotoPerfil;
      BitmapDescriptor icon;
      if (photo != null) {
        final hash = photo.hashCode;
        if (_iconPhotoHash['me'] != hash) {
          _iconPhotoHash['me'] = hash;
          _iconCache['me'] = await _circularMarker(photo, AppColors.primary);
        }
        icon = _iconCache['me']!;
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(myPos.latitude, myPos.longitude),
        infoWindow: InfoWindow(title: me?.nome ?? 'Você'),
        icon: icon,
      ));
    }

    // Marcadores dos amigos
    for (final friend in friendsProv.friends) {
      final loc = locProv.friendsLocations[friend.id];
      if (loc == null) continue;
      final photo = friend.fotoPerfil;
      BitmapDescriptor icon;
      if (photo != null) {
        final hash = photo.hashCode;
        if (_iconPhotoHash[friend.id] != hash) {
          _iconPhotoHash[friend.id] = hash;
          _iconCache[friend.id] =
              await _circularMarker(photo, AppColors.secondary);
        }
        icon = _iconCache[friend.id]!;
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }
      markers.add(Marker(
        markerId: MarkerId(friend.id),
        position: LatLng(loc.latitude, loc.longitude),
        infoWindow: InfoWindow(
          title: friend.nome,
          snippet: loc.isRecent ? 'Online agora' : 'Última vez atrás',
        ),
        icon: icon,
      ));
    }

    if (mounted) setState(() => _cachedMarkers = markers);
    _refreshing = false;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final locProv = context.watch<LocationProvider>();
    final friendsProv = context.watch<FriendsProvider>();
    final authProv = context.watch<AuthProvider>();
    final me = authProv.currentUser;
    final isSharing = locProv.isSharing;
    final myPos = locProv.myPosition;

    // Dispara atualização dos marcadores sempre que providers mudarem
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refreshMarkers(locProv, friendsProv, me),
    );

    final initialCamera = CameraPosition(
      target: myPos != null
          ? LatLng(myPos.latitude, myPos.longitude)
          : const LatLng(-23.5505, -46.6333),
      zoom: 15,
    );

    final photoB64 = me?.fotoPerfil;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: AppColors.surface,
        actions: [
          // Avatar — toque para trocar foto de perfil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _pickAndUploadPhoto(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                backgroundImage: photoB64 != null
                    ? MemoryImage(base64Decode(photoB64))
                    : null,
                child: photoB64 == null
                    ? const Icon(Icons.person, color: Colors.white70, size: 22)
                    : null,
              ),
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: () async {
              final lp = context.read<LocationProvider>();
              final fp = context.read<FriendsProvider>();
              await context.read<AuthProvider>().signOut();
              lp.reset();
              fp.reset();
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: initialCamera,
        onMapCreated: widget.onMapCreated,
        myLocationEnabled: locProv.hasPermission,
        myLocationButtonEnabled: locProv.hasPermission,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        markers: _cachedMarkers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isSharing ? AppColors.error : AppColors.primary,
        onPressed: () => context.read<LocationProvider>().toggleSharing(),
        icon: Icon(isSharing ? Icons.location_off : Icons.location_on),
        label: Text(isSharing ? 'Parar' : 'Compartilhar'),
      ),
    );
  }
}

