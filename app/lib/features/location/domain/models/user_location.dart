import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Where the user is, as far as the device can tell.
class UserLocation extends Equatable {
  const UserLocation({required this.point, required this.accuracyMeters});

  final LatLng point;

  /// Radius of the uncertainty circle around [point], in meters.
  final double accuracyMeters;

  @override
  List<Object?> get props => [point, accuracyMeters];
}
