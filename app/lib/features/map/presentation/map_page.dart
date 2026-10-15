import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_cubit.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_state.dart';
import 'package:wwu_maps_app/features/location/presentation/location_error_dialog.dart';
import 'package:wwu_maps_app/features/map/presentation/user_location_layers.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  /// Where the map starts before the first user location arrives.
  static const _campusCenter = LatLng(46.0466, -118.3888);
  static const _userZoom = 18.0;

  final _mapController = MapController();
  bool _mapReady = false;
  bool _hasCenteredOnUser = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _moveTo(UserLocation location) {
    if (!_mapReady) {
      return;
    }
    _mapController.move(location.point, _userZoom);
  }

  /// Moves the map to the user's location the first time both the map and a
  /// location fix are available.
  void _centerOnUserOnce(LocationState state) {
    if (_hasCenteredOnUser || !_mapReady || state is! LocationTracking) {
      return;
    }
    _moveTo(state.location);
    _hasCenteredOnUser = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationCubit, LocationState>(
      listener: (context, state) => _centerOnUserOnce(state),
      builder: (context, state) => Stack(
        children: [
          Scaffold(
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _campusCenter,
                    initialZoom: 16,
                    onMapReady: () {
                      _mapReady = true;
                      _centerOnUserOnce(context.read<LocationCubit>().state);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'edu.wallawalla.maps',
                    ),
                    if (state case LocationTracking(:final location))
                      ...userLocationLayers(location),
                    const SimpleAttributionWidget(
                      source: Text('OpenStreetMap contributors'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Above the Scaffold so the scrim also covers the app bar.
          if (state case LocationUnavailable(:final failure))
            LocationErrorDialog(failure: failure),
        ],
      ),
    );
  }
}
