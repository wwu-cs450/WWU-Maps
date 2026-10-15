import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wwu_maps_app/features/location/domain/location_repository.dart';
import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_state.dart';

/// Tracks the user's location for any screen that needs it.
class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this._repository) : super(const LocationLoading());

  final LocationRepository _repository;
  StreamSubscription<UserLocation>? _subscription;

  bool get canOpenSettings => _repository.canOpenSettings;

  /// Starts listening to location updates.
  void start() {
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchLocation().listen(
      (location) => emit(LocationTracking(location)),
      onError: (Object error, StackTrace stackTrace) {
        if (error is LocationException) {
          emit(LocationUnavailable(error.failure));
        } else {
          addError(error, stackTrace);
        }
      },
    );
  }

  /// Starts over after a failure, e.g. once the user has granted permission.
  void retry() {
    emit(const LocationLoading());
    start();
  }

  Future<void> openLocationSettings() => _repository.openLocationSettings();

  Future<void> openAppSettings() => _repository.openAppSettings();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
