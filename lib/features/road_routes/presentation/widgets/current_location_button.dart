import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/road_routes/application/device_location_provider.dart';
import 'package:rumboapp/features/road_routes/data/device_location_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

class CurrentLocationButton extends ConsumerWidget {
  const CurrentLocationButton({super.key, required this.onLocationSelected});

  final ValueChanged<RouteLocation> onLocationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(deviceLocationControllerProvider);
    final isLoading = locationState.isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  try {
                    final location = await ref
                        .read(deviceLocationControllerProvider.notifier)
                        .getCurrentLocation();

                    if (!context.mounted) {
                      return;
                    }

                    onLocationSelected(location);

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ubicación actual establecida como punto de partida.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  } on DeviceLocationException catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(error.message),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No fue posible obtener tu ubicación actual.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  }
                },
          icon: isLoading
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(
            isLoading ? 'Obteniendo ubicación...' : 'Usar mi ubicación actual',
          ),
        ),
      ),
    );
  }
}
