import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/app/login/login_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.title = 'Login'});

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController = TextEditingController();
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    await Core.loginController.createEmailPasswordSession(email, password);
  }

  Future<void> register(String email, String password, String name) async {
    await Core.loginController.createUser(email, password, name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'Seapruma',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge,
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const TabBar(
                      dividerHeight: 0,
                      tabs: [
                        Tab(icon: Icon(Icons.login_outlined), text: 'Entrar'),
                        Tab(
                          icon: Icon(Icons.person_add_outlined),
                          text: 'Cadastrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      height: 330,
                      child: TabBarView(
                        children: [
                          // Tab 1: Entrar
                          SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextField(
                                  controller: emailController,
                                  autofillHints: const [AutofillHints.username],
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                TextField(
                                  controller: passwordController,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: const InputDecoration(
                                    labelText: 'Senha',
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 20.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    ElevatedButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final email = emailController.text.trim();
                                        final password = passwordController.text;

                                        if (email.isEmpty) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Por favor, informe seu email.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (password.isEmpty) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Por favor, informe sua senha.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        try {
                                          await login(email, password);

                                          if (Core.loginController.status ==
                                              AuthStatus.authenticated) {
                                            Routefly.navigate(
                                              routePaths.capacitacao.path,
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Erro ao entrar: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Entrar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Tab 2: Cadastrar
                          SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextField(
                                  controller: registerNameController,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                TextField(
                                  controller: registerEmailController,
                                  autofillHints: const [AutofillHints.email],
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                TextField(
                                  controller: registerPasswordController,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Senha',
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 12.0),
                                TextField(
                                  controller: registerConfirmPasswordController,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmar Senha',
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    ElevatedButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final name =
                                            registerNameController.text.trim();
                                        final email =
                                            registerEmailController.text.trim();
                                        final password =
                                            registerPasswordController.text;
                                        final confirmPassword =
                                            registerConfirmPasswordController
                                                .text;

                                        if (name.isEmpty) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Por favor, informe seu nome.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (email.isEmpty) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Por favor, informe seu email.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (password.isEmpty) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Por favor, informe sua senha.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (password.length < 8) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'A senha deve ter no mínimo 8 caracteres.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        if (password != confirmPassword) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'As senhas não coincidem.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        try {
                                          await register(
                                            email,
                                            password,
                                            name,
                                          );
                                          if (mounted) {
                                            emailController.text = email;
                                            registerNameController.clear();
                                            registerEmailController.clear();
                                            registerPasswordController.clear();
                                            registerConfirmPasswordController
                                                .clear();

                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Conta cadastrada com sucesso! Faça login para entrar.',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Erro ao cadastrar: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Cadastrar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Observer(
                      builder: (context) {
                        return Text(
                          Core.loginController.currentUser != null
                              ? 'Autenticado como ${Core.loginController.currentUser!.name}'
                              : 'Não autenticado',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
