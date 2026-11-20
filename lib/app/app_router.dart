import 'package:flutter/material.dart';

import 'app_routes.dart';

import 'package:rumboapp/features/auth/presentation/screens/login_screen.dart';
import 'package:rumboapp/features/auth/presentation/screens/register_screen.dart';
import 'package:rumboapp/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:rumboapp/features/vehicles/presentation/screens/vehicles_screen.dart';
import 'package:rumboapp/features/trips/presentation/screens/trips_screen.dart';

import 'package:rumboapp/features/shared/presentation/screens/feature_placeholder_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _createRoute(settings, const LoginScreen());

      case AppRoutes.register:
        return _createRoute(settings, const RegisterScreen());

      case AppRoutes.forgotPassword:
        return _createRoute(settings, const ForgotPasswordScreen());

      case AppRoutes.vehicles:
        return _createRoute(settings, const VehiclesScreen());

      case AppRoutes.trips:
        return _createRoute(settings, const TripsScreen());

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
                'Aquí podrás consultar recorridos, casetas '
                'y estimaciones de gastos carreteros.',
            icon: Icons.route_outlined,
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
