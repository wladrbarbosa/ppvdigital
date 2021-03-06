import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:ppvdigital/app/app_module.dart';
import 'package:ppvdigital/app/app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  mainContext.config = ReactiveConfig(
    isSpyEnabled: true,
  );

  mainContext.spy((event) {
    // ignore: avoid_print
    print(event);
  });

  Intl.defaultLocale = 'pt_BR';
  initializeDateFormatting(Intl.defaultLocale);
  runApp(ModularApp(module: AppModule(), child: AppWidget()));
}
