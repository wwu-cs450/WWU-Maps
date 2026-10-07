import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'services/location_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WWU Maps',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.black)),
      home: const HomePage(title: 'WWU Maps'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.title,
    this.locationService = const LocationService(),
  });

  final String title;
  final LocationService locationService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Position>? _positionSubscription;
  Position? _position;
  LocationFailure? _failure;

  @override
  void initState() {
    super.initState();
    _listenToLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _listenToLocation() {
    _positionSubscription?.cancel();
    setState(() => _failure = null);
    _positionSubscription = widget.locationService.positionStream().listen(
      (position) => setState(() {
        _position = position;
        _failure = null;
      }),
      onError: (Object error) {
        if (error is LocationException) {
          setState(() => _failure = error.failure);
        } else {
          debugPrint('Location error: $error');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: locationStatus(context)),
    );
  }

  Widget locationStatus(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(LocationException(failure).message),
          const SizedBox(height: 12),
          if (!kIsWeb && failure == LocationFailure.serviceDisabled)
            TextButton(
              onPressed: widget.locationService.openLocationSettings,
              child: const Text('Open location settings'),
            ),
          if (!kIsWeb && failure == LocationFailure.permissionDeniedForever)
            TextButton(
              onPressed: widget.locationService.openAppSettings,
              child: const Text('Open app settings'),
            ),
          FilledButton(
            onPressed: _listenToLocation,
            child: const Text('Try again'),
          ),
        ],
      );
    }

    final position = _position;
    if (position == null) {
      return const CircularProgressIndicator();
    }

    return Text(
      '${position.latitude.toStringAsFixed(6)}, '
      '${position.longitude.toStringAsFixed(6)}\n'
      '±${position.accuracy.toStringAsFixed(0)} m',
      textAlign: TextAlign.center,
    );
  }
}
