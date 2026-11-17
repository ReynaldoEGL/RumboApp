import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/fonts/manrope/OFL.txt',
    );

    yield LicenseEntryWithLineBreaks(['Manrope'], license);
  });

  runApp(const ProviderScope(child: RumboApp()));
}
