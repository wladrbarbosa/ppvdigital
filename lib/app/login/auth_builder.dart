import 'package:flutter/material.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:routefly/routefly.dart';

class AuthBuilder extends StatefulWidget {
  const AuthBuilder({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  _AuthBuilderState createState() => _AuthBuilderState();
}

class _AuthBuilderState extends State<AuthBuilder> {
  @override
  void initState() {
    super.initState();
    Core.instance.loginController.addStatusListener(checkAuth);
  }

  @override
  void dispose() {
    Core.instance.loginController.removeStatusListener(checkAuth);
    super.dispose();
  }

  void checkAuth(AuthStatus status) {
    Core.instance.loginController.checkAuthentication(Routefly.currentUri.path);
  }

  @override
  Widget build(BuildContext context) =>  widget.child;
}
