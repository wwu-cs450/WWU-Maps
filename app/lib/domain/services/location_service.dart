import 'package:geolocator/geolocator.dart';

/// Why the device location could not be accessed.
enum LocationFailure {
  /// Location services (GPS) are turned off on the device.
  serviceDisabled,

  /// The user denied the permission request. We may ask again later.
  permissionDenied,

  /// The user permanently denied the permission. It can only be granted
  /// again from the app's system settings.
  permissionDeniedForever,
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  String get message => switch (failure) {
    LocationFailure.serviceDisabled => 'Location services are turned off.',
    LocationFailure.permissionDenied => 'Location permission was denied.',
    LocationFailure.permissionDeniedForever =>
      'Location permission is permanently denied. '
          'Enable it in the app settings.',
  };

  @override
  String toString() => 'LocationException: $message';
}

/// Thin wrapper around the geolocator plugin that handles service and
/// permission checks before reading the device position.
class LocationService {
  const LocationService();

  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    // Only emit a new position after moving at least this many meters.
    distanceFilter: 5,
  );

  /// Makes sure location services are on and permission is granted,
  /// requesting permission if needed. Throws a [LocationException] otherwise.
  Future<void> ensurePermission() async {
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

  /// Returns the device's current position.
  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(locationSettings: _settings);
  }

  /// Emits the device position whenever it changes.
  Stream<Position> positionStream() async* {
    await ensurePermission();
    yield* Geolocator.getPositionStream(locationSettings: _settings);
  }

  /// Opens the system location settings (e.g. to turn on GPS).
  /// Not supported on web.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens this app's system settings page (e.g. to grant permission after
  /// it was permanently denied). Not supported on web.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
