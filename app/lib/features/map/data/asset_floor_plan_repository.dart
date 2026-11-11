import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:wwu_maps_app/features/map/domain/floor_plan_repository.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_plan.dart';
import 'package:wwu_maps_app/features/map/domain/models/floor_unit.dart';

/// Loads floor plans bundled with the app, from
/// `assets/maps/<building>/<building>_Floor<level>.geojson`.
class AssetFloorPlanRepository implements FloorPlanRepository {
  const AssetFloorPlanRepository();

  @override
  Future<FloorPlan> floorPlan(String building, int level) async {
    final source = await rootBundle.loadString(
      'assets/maps/$building/${building}_Floor$level.geojson',
    );
    return parseFloorPlanGeoJson(source);
  }

  /// Reads a floor plan from GeoJSON.
  ///
  /// Each feature's `feature_type` says what it is:
  /// - one `level` polygon (the floor outline, with `building` and `ordinal`),
  /// - `unit` polygons,
  /// - `opening` lines (doors).
  static FloorPlan parseFloorPlanGeoJson(String source) {
    final collection = jsonDecode(source) as Map<String, dynamic>;
    final features = (collection['features'] as List)
        .cast<Map<String, dynamic>>();

    Map<String, dynamic>? level;
    final units = <FloorUnit>[];
    final doors = <FloorSegment>[];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final category = properties['category'] as String?;

      switch (properties['feature_type']) {
        case 'level':
          level = feature;
        case 'unit':
          final unitCategory = UnitType.values.asNameMap()[category];
          if (unitCategory == null) {
            continue;
          }
          units.add(
            FloorUnit(
              type: unitCategory,
              outline: _ring(geometry),
              name: properties['name'] as String?,
            ),
          );
        case 'opening' when category == 'door':
          doors.add(_segment(geometry));
      }
    }

    if (level == null) {
      throw const FormatException('Floor plan has no "level" feature.');
    }
    final levelProperties = level['properties'] as Map<String, dynamic>;
    return FloorPlan(
      building: levelProperties['building'] as String,
      level: (levelProperties['ordinal'] as num).toInt(),
      outline: _ring(level['geometry'] as Map<String, dynamic>),
      units: units,
      doors: doors,
    );
  }

  static LatLng _point(Object? position) {
    final [lng, lat, ...] = (position as List).cast<num>();
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  /// The exterior ring of a Polygon, without GeoJSON's repeated closing point.
  static List<LatLng> _ring(Map<String, dynamic> geometry) {
    if (geometry['type'] != 'Polygon') {
      throw FormatException('Expected a Polygon, got ${geometry['type']}.');
    }
    final rings = geometry['coordinates'] as List;
    final points = (rings.first as List).map(_point).toList();
    if (points.length > 1 && points.first == points.last) {
      points.removeLast();
    }
    return points;
  }

  static FloorSegment _segment(Map<String, dynamic> geometry) {
    if (geometry['type'] != 'LineString') {
      throw FormatException('Expected a LineString, got ${geometry['type']}.');
    }
    final points = geometry['coordinates'] as List;
    return (_point(points.first), _point(points.last));
  }
}
