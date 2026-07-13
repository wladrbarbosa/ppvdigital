import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/local/app_database.dart';
import 'package:ppvdigital/root_app_widget.dart';

import 'package:ppvdigital/timezone_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureTimeZones();

  setUrlStrategy(PathUrlStrategy());
  mainContext.config = ReactiveConfig(isSpyEnabled: true);

  mainContext.spy((event) {
    // ignore: avoid_print
    log(event.toString());
  });

  Intl.defaultLocale = 'pt_BR';
  initializeDateFormatting(Intl.defaultLocale);

  final database = AppDatabase();
  Core.initialize(database);

  runApp(RootAppWidget());
}
