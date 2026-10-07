import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:wwu_maps_app/main.dart';
import 'package:wwu_maps_app/services/location_service.dart';

class FakeLocationService extends LocationService {
  FakeLocationService(this._stream);

  final Stream<Position> _stream;

  @override
  Stream<Position> positionStream() => _stream;
}

Position _position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime(2026),
  accuracy: 8,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  testWidgets('shows the current position', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          title: 'WWU Maps',
          locationService: FakeLocationService(
            Stream.value(_position(48.734, -122.486)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('48.734000, -122.486000\n±8 m'), findsOneWidget);
  });

  testWidgets('shows an error when permission is denied', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          title: 'WWU Maps',
          locationService: FakeLocationService(
            Stream.error(
              const LocationException(LocationFailure.permissionDenied),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Location permission was denied.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
