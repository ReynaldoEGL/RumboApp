import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/road_routes/application/device_location_provider.dart';
import 'package:rumboapp/features/road_routes/application/road_route_planner_provider.dart';
import 'package:rumboapp/features/road_routes/data/device_location_service.dart';
import 'package:rumboapp/features/road_routes/domain/route_location.dart';

class CurrentLocationButton extends ConsumerWidget {
  const CurrentLocationButton({super.key, required this.onLocationSelected});

  final ValueChanged<RouteLocation> onLocationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(deviceLocationControllerProvider);
    final origin = ref.watch(roadRoutePlannerProvider).origin;
    final gpsOrigin = origin?.resultType == 'deviceLocation' ? origin : null;
    final isLoading = locationState.isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
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
                                'Ubicación actual establecida como origen.',
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
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                isLoading
                    ? 'Obteniendo ubicación...'
                    : 'Usar mi ubicación actual',
              ),
            ),
          ),
          if (gpsOrigin != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 17,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      gpsOrigin.addressLabel,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
