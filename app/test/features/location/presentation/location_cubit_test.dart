import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_cubit.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_state.dart';

import '../../../mocks/mock_location_repository.dart';

void main() {
  late MockLocationRepository repository;

  setUp(() => repository = MockLocationRepository());

  test('starts out loading', () {
    expect(LocationCubit(repository).state, const LocationLoading());
  });

  blocTest<LocationCubit, LocationState>(
    'emits each new location',
    build: () => LocationCubit(repository),
    act: (cubit) {
      cubit.start();
      repository.emitLocation(userLocation(46.0466, -118.3888));
      repository.emitLocation(userLocation(46.0470, -118.3890));
    },
    expect: () => [
      LocationTracking(userLocation(46.0466, -118.3888)),
      LocationTracking(userLocation(46.0470, -118.3890)),
    ],
  );

  blocTest<LocationCubit, LocationState>(
    'emits the failure when location is unavailable',
    build: () => LocationCubit(repository),
    act: (cubit) {
      cubit.start();
      repository.fail(LocationFailure.permissionDenied);
    },
    expect: () => [const LocationUnavailable(LocationFailure.permissionDenied)],
  );

  blocTest<LocationCubit, LocationState>(
    'reports unexpected errors without changing state',
    build: () => LocationCubit(repository),
    act: (cubit) {
      cubit.start();
      repository.emitError(StateError('plugin crashed'));
    },
    expect: () => <LocationState>[],
    errors: () => [isA<StateError>()],
  );

  blocTest<LocationCubit, LocationState>(
    'retry goes back to loading and listens again',
    build: () => LocationCubit(repository),
    act: (cubit) async {
      cubit.start();
      repository.fail(LocationFailure.serviceDisabled);
      await Future<void>.delayed(Duration.zero);
      cubit.retry();
      repository.emitLocation(userLocation(46.0466, -118.3888));
    },
    expect: () => [
      const LocationUnavailable(LocationFailure.serviceDisabled),
      const LocationLoading(),
      LocationTracking(userLocation(46.0466, -118.3888)),
    ],
    verify: (_) => expect(repository.watchCount, 2),
  );

  test('close stops listening to location updates', () async {
    final cubit = LocationCubit(repository)..start();
    expect(repository.hasListener, isTrue);

    await cubit.close();

    expect(repository.hasListener, isFalse);
  });
}
