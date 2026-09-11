import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_layout.dart';
import 'package:ppvdigital/app/login/auth_builder.dart';
import 'package:ppvdigital/controllers/theme_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/l10n/app_localizations.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:ppvdigital/theme.dart';
import 'package:ppvdigital/util.dart';
import 'package:routefly/routefly.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class RootAppWidget extends StatefulWidget {
  const RootAppWidget({super.key});

  @override
  State<RootAppWidget> createState() => _RootAppWidgetState();
}

class _RootAppWidgetState extends State<RootAppWidget>
    with WidgetsBindingObserver {
  MaterialTheme? _materialTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_materialTheme == null) {
      final TextTheme textTheme = createTextTheme(
        context,
        'Plus Jakarta Sans',
        'Plus Jakarta Sans',
      );
      _materialTheme = MaterialTheme(textTheme);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log('AppLifecycleState.resumed');
      if (Core.loginController.currentUser != null) {
        Core.financasController.loadDocuments(forceSync: true);
        Core.tarefasHabitosController.loadDocuments(forceSync: true);
      }
      if (kIsWeb) {
        WidgetsBinding.instance.scheduleFrame();
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) setState(() {});
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  FutureOr<RouteInformation> _guardRoute(RouteInformation routeInformation) {
    log(routeInformation.uri.path);

    if (TarefasPageState.tabController != null &&
        routeInformation.uri.path.contains('/capacitacao/tarefas_habitos')) {
      if (!TarefasPageState.fromTabClick) {
        final targetIndex = switch (routeInformation.uri.path) {
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.dashboard =>
            0,
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.tarefas =>
            1,
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.habitos =>
            2,
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.calendario =>
            3,
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.categorias =>
            4,
          _ => 0,
        };

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Core.globalKey.currentContext
              ?.findAncestorStateOfType<TarefasPageState>()
              ?.updateTabIndex(targetIndex);
        });
      } else {
        TarefasPageState.fromTabClick = false;
      }
    }

    return routeInformation;
  }

  @override
  Widget build(BuildContext context) {
    final List<LocalizationsDelegate<dynamic>> appLocalizationDelegates =
        List.from(AppLocalizations.localizationsDelegates);

    final MaterialTheme theme = _materialTheme ??
        MaterialTheme(
          createTextTheme(
            context,
            'Plus Jakarta Sans',
            'Plus Jakarta Sans',
          ),
        );

    if (!appLocalizationDelegates.contains(SfGlobalLocalizations.delegate)) {
      appLocalizationDelegates.add(SfGlobalLocalizations.delegate);
    }

    return Observer(
      builder: (context) {
        final currentPalette = Core.getIt.isRegistered<ThemeController>()
            ? Core.themeController.palette
            : AppThemePalette.menta;
        final currentMode = Core.getIt.isRegistered<ThemeController>()
            ? Core.themeController.themeMode
            : ThemeMode.system;

        return MaterialApp.router(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AuthBuilder(child: child!),
          routerConfig: Routefly.routerConfig(
            routes: routes,
            initialPath: routePaths.path,
            middlewares: [_guardRoute],
          ),
          debugShowCheckedModeBanner: false,
          title: 'Seapruma',
          themeMode: currentMode,
          theme: theme.light(currentPalette),
          darkTheme: theme.dark(currentPalette),
        );
      },
    );
  }
}
