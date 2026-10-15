import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:wwu_maps_app/features/location/domain/models/user_location.dart';

/// The accuracy circle and the blue dot marking the user's location.
List<Widget> userLocationLayers(UserLocation location) {
  const blue = Color(0xFF1A73E8);

  return [
    CircleLayer(
      circles: [
        CircleMarker(
          point: location.point,
          radius: location.accuracyMeters,
          useRadiusInMeter: true,
          color: blue.withValues(alpha: 0.15),
          borderColor: blue.withValues(alpha: 0.4),
          borderStrokeWidth: 1,
        ),
      ],
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: location.point,
          width: 22,
          height: 22,
          child: Container(
            key: const ValueKey('user-location-dot'),
            decoration: BoxDecoration(
              color: blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
          ),
        ),
      ],
    ),
  ];
}
