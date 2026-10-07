import 'package:equatable/equatable.dart';

import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';

sealed class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

/// Waiting for permission or the first location fix.
final class LocationLoading extends LocationState {
  const LocationLoading();
}

final class LocationTracking extends LocationState {
  const LocationTracking(this.location);

  final UserLocation location;

  @override
  List<Object?> get props => [location];
}

final class LocationUnavailable extends LocationState {
  const LocationUnavailable(this.failure);

  final LocationFailure failure;

  @override
  List<Object?> get props => [failure];
}
