import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:ppvdigital/root_app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());
  mainContext.config = ReactiveConfig(
    isSpyEnabled: true,
  );

  mainContext.spy((event) {
    // ignore: avoid_print
    print(event);
  });

  Intl.defaultLocale = 'pt_BR';
  initializeDateFormatting(Intl.defaultLocale);
  runApp(RootAppWidget());
}
