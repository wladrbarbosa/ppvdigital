import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_layout.dart';
import 'package:ppvdigital/app/login/auth_builder.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:ppvdigital/theme.dart';
import 'package:ppvdigital/util.dart';
import 'package:routefly/routefly.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class RootAppWidget extends StatelessWidget {
  FutureOr<RouteInformation> _guardRoute(RouteInformation routeInformation) {
    print(routeInformation.uri.path);

    if (TarefasPageState.tabController != null && routeInformation.uri.path.contains('/capacitacao/tarefas_habitos')) {
      switch (routeInformation.uri.path) {
        case final String url when url == routePaths.capacitacao.tarefasHabitos.calendario:
          TarefasPageState.tabController!.index = 1;
        case final String url when url == routePaths.capacitacao.tarefasHabitos.categorias:
          TarefasPageState.tabController!.index = 2;
        case final String url when url == routePaths.capacitacao.tarefasHabitos.historico:
          TarefasPageState.tabController!.index = 3;
        default:
          TarefasPageState.tabController!.index = 0;
      }

      TarefasPageState.globalKey = GlobalKey();
    }

    return routeInformation;
  }

  @override
  Widget build(BuildContext context) {
    final List<LocalizationsDelegate<dynamic>> appLocalizationDelegates = List.from(AppLocalizations.localizationsDelegates);
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    final TextTheme textTheme = createTextTheme(context, 'Acme', 'Akaya Kanadaka');
    final MaterialTheme theme = MaterialTheme(textTheme);

    if (!appLocalizationDelegates.contains(SfGlobalLocalizations.delegate)) {
      appLocalizationDelegates.add(SfGlobalLocalizations.delegate);
    }

    return MaterialApp.router(
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AuthBuilder(child: child!,),
      routerConfig: Routefly.routerConfig(
        routes: routes,
        initialPath: routePaths.path,
        middlewares: [
          _guardRoute,
        ],
      ),
      debugShowCheckedModeBanner: false,
      title: 'PPV Digital',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
    );
  }
}
