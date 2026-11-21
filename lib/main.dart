import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:rumboapp/app/app.dart';
import 'package:rumboapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      '[Rumbo] Firebase inicializado correctamente. '
      'Proyecto: ${firebaseApp.options.projectId}',
    );
  } catch (error, stackTrace) {
    debugPrint('[Rumbo] Error al inicializar Firebase: $error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/manrope/OFL.txt');

    yield LicenseEntryWithLineBreaks(['Manrope'], license);
  });

  runApp(const ProviderScope(child: RumboApp()));
}
