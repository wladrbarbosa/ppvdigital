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
    Core.loginController.addStatusListener(checkAuth);
  }

  @override
  void dispose() {
    Core.loginController.removeStatusListener(checkAuth);
    super.dispose();
  }

  void checkAuth(AuthStatus status) {
    Core.loginController.checkAuthentication(Routefly.currentUri.path);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: Colors.transparent,
            child: IgnorePointer(
              child: Text(
                'v${Core.appVersion}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
