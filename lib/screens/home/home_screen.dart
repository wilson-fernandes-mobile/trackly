// ============================================================
//  home_screen.dart
//  Tela principal: mapa com marcadores dos amigos + navegação.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/friends_provider.dart';
import '../../utils/constants.dart';
import '../friends/friends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // ignore: unused_field — reservado para controle programático do mapa (ex: centralizar)
  GoogleMapController? _mapController;
  bool _initialized = false;

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

  // Sincroniza amigos com o LocationProvider quando mudam
  void _syncFriendLocations(List<String> friendIds) {
    context.read<LocationProvider>().updateFriendIds(friendIds);
  }

  @override
  Widget build(BuildContext context) {
    final friendIds = context.select<FriendsProvider, List<String>>(
      (f) => f.friendIds,
    );
    // Sincroniza sempre que a lista de amigos mudar
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncFriendLocations(friendIds),
    );

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

class _MapTab extends StatelessWidget {
  final void Function(GoogleMapController) onMapCreated;
  const _MapTab({required this.onMapCreated});

  Set<Marker> _buildMarkers(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final friendsProv = context.watch<FriendsProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final markers = <Marker>{};

    // Marcador do usuário logado
    if (locationProv.myPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(
            locationProv.myPosition!.latitude,
            locationProv.myPosition!.longitude,
          ),
          infoWindow: InfoWindow(title: currentUser?.nome ?? 'Você'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Marcadores dos amigos
    for (final friend in friendsProv.friends) {
      final loc = locationProv.friendsLocations[friend.id];
      if (loc == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId(friend.id),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(
            title: friend.nome,
            snippet: loc.isRecent ? 'Online agora' : 'Última vez atrás',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final locationProv = context.watch<LocationProvider>();
    final isSharing = locationProv.isSharing;
    final myPos = locationProv.myPosition;

    final initialCamera = CameraPosition(
      target: myPos != null
          ? LatLng(myPos.latitude, myPos.longitude)
          : const LatLng(-23.5505, -46.6333), // São Paulo como fallback
      zoom: 15,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        backgroundColor: AppColors.surface,
        actions: [
          // Botão de logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair',
            onPressed: () async {
              final locationProv = context.read<LocationProvider>();
              final friendsProv = context.read<FriendsProvider>();
              await context.read<AuthProvider>().signOut();
              locationProv.reset();
              friendsProv.reset();
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: initialCamera,
        onMapCreated: onMapCreated,
        myLocationEnabled: locationProv.hasPermission, // ponto azul nativo
        myLocationButtonEnabled: locationProv.hasPermission, // botão centralizar
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        markers: _buildMarkers(context),
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

