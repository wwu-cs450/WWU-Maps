import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';

abstract interface class LocationRepository {
  /// Emits the user's location whenever it changes.
  ///
  /// Checks (and if needed requests) permission first. Emits a
  /// [LocationException] error and closes if location is unavailable.
  Stream<UserLocation> watchLocation();

  /// Whether this platform can open the system settings pages below.
  bool get canOpenSettings;

  /// Opens the system location settings (e.g. to turn on GPS).
  Future<bool> openLocationSettings();

  /// Opens this app's system settings page (e.g. to grant permission after
  /// it was permanently denied).
  Future<bool> openAppSettings();
}
