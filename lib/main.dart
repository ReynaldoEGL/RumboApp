import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:rumboapp/app/app.dart';
import 'package:rumboapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase con la configuración de la plataforma.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar la licencia de la tipografía Manrope.
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/manrope/OFL.txt',
    );

    yield LicenseEntryWithLineBreaks(['Manrope'], license);
  });

  runApp(const ProviderScope(child: RumboApp()));
}
