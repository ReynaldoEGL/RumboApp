import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/shared/presentation/screens/feature_placeholder_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _createRoute(settings, const HomeScreen());

      case AppRoutes.documents:
        return _createRoute(
          settings,
          const FeaturePlaceholderScreen(
            title: 'Documentos',
            description:
                'Aquí podrás organizar pasaportes, visas, '
                'identificaciones y fechas de vencimiento.',
            icon: Icons.folder_copy_outlined,
          ),
        );

      case AppRoutes.roadRoutes:
        return _createRoute(
          settings,
          const FeaturePlaceholderScreen(
            title: 'Rutas y casetas',
            description:
                'Aquí podrás consultar recorridos, '
                'casetas y estimaciones de gastos carreteros.',
            icon: Icons.route_outlined,
          ),
        );

      case AppRoutes.trips:
        return _createRoute(
          settings,
          const FeaturePlaceholderScreen(
            title: 'Mis viajes',
            description:
                'Aquí podrás reunir tus itinerarios, '
                'presupuestos y pendientes de viaje.',
            icon: Icons.luggage_outlined,
          ),
        );

      default:
        return _createRoute(
          settings,
          const FeaturePlaceholderScreen(
            title: 'Pantalla no encontrada',
            description: 'La dirección solicitada no está disponible.',
            icon: Icons.explore_off_outlined,
          ),
        );
    }
  }

  static MaterialPageRoute<void> _createRoute(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
