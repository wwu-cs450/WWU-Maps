import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class OpenStreetMapLayer extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25, // Faded so the floor plans on top stand out.
      child: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'edu.wallawalla.maps',
      ),
    );
  }
}
