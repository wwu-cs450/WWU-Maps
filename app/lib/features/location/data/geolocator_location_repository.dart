import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/location/domain/location_repository.dart';
import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';

/// [LocationRepository] backed by the geolocator plugin.
class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.best,
    // Only emit a new position after moving at least this many meters.
    distanceFilter: 5,
  );

  @override
  Stream<UserLocation> watchLocation() async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(locationSettings: _settings)
        .map(_toUserLocation);
  }

  @override
  bool get canOpenSettings => !kIsWeb;

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Makes sure location services are on and permission is granted,
  /// requesting permission if needed. Throws a [LocationException] otherwise.
  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationFailure.permissionDenied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationFailure.permissionDeniedForever);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        return;
    }
  }

  static UserLocation _toUserLocation(Position position) => UserLocation(
    point: LatLng(position.latitude, position.longitude),
    accuracyMeters: position.accuracy,
  );
}
