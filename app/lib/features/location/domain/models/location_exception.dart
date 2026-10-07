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

/// Thrown (or emitted as a stream error) by a [LocationRepository] when the
/// location cannot be read for one of the known [LocationFailure] reasons.
class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationException: ${failure.name}';
}
