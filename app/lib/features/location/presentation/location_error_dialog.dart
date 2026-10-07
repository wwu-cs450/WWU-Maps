import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wwu_maps_app/features/location/domain/models/location_exception.dart';
import 'package:wwu_maps_app/features/location/presentation/cubit/location_cubit.dart';

extension LocationFailureMessage on LocationFailure {
  String get message => switch (this) {
    LocationFailure.serviceDisabled => 'Location services are turned off.',
    LocationFailure.permissionDenied => 'Location permission was denied.',
    LocationFailure.permissionDeniedForever =>
      'Location permission is permanently denied. '
          'Enable it in the app settings.',
  };
}

/// Explains why the location is unavailable and offers a way to fix it.
class LocationErrorDialog extends StatelessWidget {
  const LocationErrorDialog({required this.failure, super.key});

  final LocationFailure failure;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocationCubit>();

    // Hides the content underneath from screen readers, like a dialog route.
    return BlockSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(
            dismissible: false,
            color: DialogTheme.of(context).barrierColor ?? Colors.black54,
          ),
          AlertDialog(
            title: const Text('Location unavailable'),
            content: Text(failure.message),
            actions: [
              if (cubit.canOpenSettings &&
                  failure == LocationFailure.serviceDisabled)
                TextButton(
                  onPressed: cubit.openLocationSettings,
                  child: const Text('Open location settings'),
                ),
              if (cubit.canOpenSettings &&
                  failure == LocationFailure.permissionDeniedForever)
                TextButton(
                  onPressed: cubit.openAppSettings,
                  child: const Text('Open app settings'),
                ),
              FilledButton(
                onPressed: cubit.retry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
