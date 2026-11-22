import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wwu_maps_app/features/location/data/geolocator_location_repository.dart';
import 'package:wwu_maps_app/features/location/domain/location_repository.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_cubit.dart';
import 'package:wwu_maps_app/features/map/data/asset_floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/presentation/map_page.dart';
import 'package:wwu_maps_app/features/path-planning/data/predefined_path_planning_repository.dart';
import 'package:wwu_maps_app/features/path-planning/domain/path_planning_repository.dart';
import 'package:wwu_maps_app/features/path-planning/presentation/cubit/path_planning_cubit.dart';
import 'package:wwu_maps_app/features/search/data/floor_plan_room_repository.dart';
import 'package:wwu_maps_app/features/search/domain/room_repository.dart';
import 'package:wwu_maps_app/features/search/presentation/cubit/search_cubit.dart';

void main() {
  const floorPlanRepository = AssetFloorPlanRepository();
  runApp(
    MainApp(
      locationRepository: const GeolocatorLocationRepository(),
      roomRepository: FloorPlanRoomRepository(floorPlanRepository),
      floorPlanRepository: floorPlanRepository,
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({
    required this.locationRepository,
    required this.roomRepository,
    required this.floorPlanRepository,
    this.pathPlanningRepository,
    super.key,
  });

  final LocationRepository locationRepository;
  final RoomRepository roomRepository;
  final FloorPlanRepository floorPlanRepository;
  final PathPlanningRepository? pathPlanningRepository;

  @override
  Widget build(BuildContext context) {
    final pathPlanningRepository =
        this.pathPlanningRepository ?? PredefinedPathPlanningRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: locationRepository),
        RepositoryProvider.value(value: roomRepository),
        RepositoryProvider.value(value: floorPlanRepository),
        RepositoryProvider<PathPlanningRepository>.value(
          value: pathPlanningRepository,
        ),
      ],
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
            searchBarTheme: const SearchBarThemeData(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
            ),
          ),
          // Only the map screen searches, so the cubit lives around it.
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    SearchCubit(context.read<RoomRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    PathPlanningCubit(context.read<PathPlanningRepository>())
                      ..showShortestPath('r_301', 'r_302'),
              ),
            ],
            child: const MapPage(),
          ),
        ),
      ),
    );
  }
}
