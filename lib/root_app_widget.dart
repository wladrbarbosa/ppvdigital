import 'package:flutter/material.dart';
import 'package:ppvdigital/app/login/auth_builder.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:ppvdigital/theme.dart';
import 'package:ppvdigital/util.dart';
import 'package:routefly/routefly.dart';

class RootAppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    final TextTheme textTheme = createTextTheme(context, 'Acme', 'Akaya Kanadaka');
    final MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      builder: (context, child) => AuthBuilder(child: child!,),
      routerConfig: Routefly.routerConfig(
        routes: routes,
        initialPath: routePaths.path,
      ),
      debugShowCheckedModeBanner: false,
      title: 'PPV Digital',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
    );
  }
}
