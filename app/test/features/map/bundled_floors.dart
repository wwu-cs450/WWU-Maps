import 'dart:io';

import 'package:wwu_maps_app/features/map/data/asset_floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';

/// The KRH-CSP floors bundled with the app.
const bundledFloors = [1, 2, 3];

/// Reads bundled KRH-CSP floor [level] straight from the asset file.
FloorPlan bundledFloor(int level) =>
    AssetFloorPlanRepository.parseFloorPlanGeoJson(
      File('assets/maps/KRH-CSP/KRH-CSP_Floor$level.geojson')
          .readAsStringSync(),
    );
