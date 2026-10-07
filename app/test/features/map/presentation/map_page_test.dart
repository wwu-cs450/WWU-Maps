import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/main.dart';

import '../../../mocks/mock_location_repository.dart';

void main() {
  late MockLocationRepository repository;

  setUp(() => repository = MockLocationRepository());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MainApp(locationRepository: repository));
    await tester.pump();
  }

  /// The first pump delivers the stream event to the cubit, the second one
  /// rebuilds the widgets with the cubit's new state.
  Future<void> pumpLocationUpdate(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows a dot at the current location', (tester) async {
    await pumpApp(tester);
    repository.emitLocation(userLocation(46.0466, -118.3888));
    await pumpLocationUpdate(tester);

    expect(find.byKey(const ValueKey('user-location-dot')), findsOneWidget);
    expect(find.byTooltip('Center on my location'), findsOneWidget);
  });

  testWidgets('shows an error when permission is denied', (tester) async {
    await pumpApp(tester);
    repository.fail(LocationFailure.permissionDenied);
    await pumpLocationUpdate(tester);

    expect(find.text('Location permission was denied.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byTooltip('Center on my location'), findsNothing);
  });

  testWidgets('try again listens for the location again', (tester) async {
    await pumpApp(tester);
    repository.fail(LocationFailure.permissionDenied);
    await pumpLocationUpdate(tester);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(repository.watchCount, 2);
    expect(find.text('Location permission was denied.'), findsNothing);
  });

  testWidgets('offers app settings when permission is permanently denied', (
    tester,
  ) async {
    await pumpApp(tester);
    repository.fail(LocationFailure.permissionDeniedForever);
    await pumpLocationUpdate(tester);

    await tester.tap(find.text('Open app settings'));

    expect(repository.openAppSettingsCalls, 1);
  });

  testWidgets('hides settings buttons where they are unsupported', (
    tester,
  ) async {
    repository = MockLocationRepository(canOpenSettings: false);
    await pumpApp(tester);
    repository.fail(LocationFailure.serviceDisabled);
    await pumpLocationUpdate(tester);

    expect(find.text('Open location settings'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
}
