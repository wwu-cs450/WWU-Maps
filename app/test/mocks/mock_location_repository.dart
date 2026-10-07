import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/location/domain/location_repository.dart';
import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';

UserLocation userLocation(double latitude, double longitude) =>
    UserLocation(point: LatLng(latitude, longitude), accuracyMeters: 8);

/// A [LocationRepository] whose location stream the test drives by hand.
class MockLocationRepository implements LocationRepository {
  MockLocationRepository({this.canOpenSettings = true});

  final _controllers = <StreamController<UserLocation>>[];
  int openLocationSettingsCalls = 0;
  int openAppSettingsCalls = 0;

  /// How many times [watchLocation] was called.
  int get watchCount => _controllers.length;

  /// Whether anyone still listens to the latest location stream.
  bool get hasListener => _controllers.last.hasListener;

  void emitLocation(UserLocation location) => _controllers.last.add(location);

  void emitError(Object error) => _controllers.last.addError(error);

  void fail(LocationFailure failure) => emitError(LocationException(failure));

  @override
  Stream<UserLocation> watchLocation() {
    final controller = StreamController<UserLocation>();
    _controllers.add(controller);
    return controller.stream;
  }

  @override
  final bool canOpenSettings;

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return true;
  }
}
