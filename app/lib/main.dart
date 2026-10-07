import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wwu_maps_app/features/location/domain/location_repository.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_cubit.dart';
import 'package:wwu_maps_app/features/map/presentation/map_page.dart';

import 'features/location/data/geolocator_location_repository.dart';

void main() {
  runApp(const MainApp(locationRepository: GeolocatorLocationRepository()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.locationRepository});

  final LocationRepository locationRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: locationRepository,
      child: BlocProvider(
        create: (context) =>
            LocationCubit(context.read<LocationRepository>())..start(),
        child: MaterialApp(
          title: 'WWU Maps',
          theme: ThemeData(
            colorScheme: .fromSeed(
              seedColor: Colors.black,
              dynamicSchemeVariant: .monochrome,
            ),
          ),
          home: const MapPage(),
        ),
      ),
    );
  }
}
