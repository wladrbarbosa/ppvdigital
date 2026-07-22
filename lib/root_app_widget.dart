import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_layout.dart';
import 'package:ppvdigital/app/login/auth_builder.dart';
import 'package:ppvdigital/core.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
              when url == routePaths.capacitacao.tarefasHabitos.habitos =>
            1,
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.calendario =>
            2,
          final String url
              when url == routePaths.capacitacao.tarefasHabitos.categorias =>
            3,
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
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    final TextTheme textTheme = createTextTheme(
      context,
      'Acme',
      'Akaya Kanadaka',
    );
    final MaterialTheme theme = MaterialTheme(textTheme);

    if (!appLocalizationDelegates.contains(SfGlobalLocalizations.delegate)) {
      appLocalizationDelegates.add(SfGlobalLocalizations.delegate);
    }

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
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
    );
  }
}
