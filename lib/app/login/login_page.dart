import 'package:flutter/material.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.title = 'Login',
  });
  
  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  Future<void> login(String email, String password) async {
    await Core.instance.loginController.createEmailPasswordSession(email, password);
  }

  Future<void> register(String email, String password, String name) async {
    await Core.instance.loginController.createUser(email, password, name);
  }

  Future<void> logout() async {
    await Core.instance.loginController.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Projeto Pessoal de Vida\nDigital',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16.0,),
                const TabBar(
                  dividerHeight: 0,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.login_outlined),
                      text: 'Entrar',
                    ),
                    Tab(
                      icon: Icon(Icons.add_reaction_rounded),
                      text: 'Cadastrar',
                    ),
                  ],
                ),
                const SizedBox(height: 16.0,),
                SizedBox(
                  height: 250,
                  child: TabBarView(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(labelText: 'Email',),
                          ),
                          const SizedBox(height: 16.0,),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: () async {
                                  await login(emailController.text, passwordController.text);

                                  if (Core.instance.loginController.status != null) {
                                    Routefly.navigate(routePaths.home);
                                  }
                                },
                                child: const Text('Entrar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(labelText: 'Email',),
                          ),
                          const SizedBox(height: 16.0,),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Nome'),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                onPressed: () {
                                  register(emailController.text, passwordController.text,
                                      nameController.text,);
                                },
                                child: const Text('Cadastrar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(Core.instance.loginController.currentUser != null
                    ? 'Autenticado como ${Core.instance.loginController.currentUser!.name}'
                    : 'Não autenticado',),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
