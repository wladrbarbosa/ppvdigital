import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class LoginController extends LoginControllerBase {}

abstract class LoginControllerBase {
  // Constructor
  LoginControllerBase() {
    init();
    loadUser();
    _status = mobx.ObservableStream<AuthStatus>(_statusStreamController.stream, name: 'status');
  }

  late final StreamController<AuthStatus> _statusStreamController = StreamController<AuthStatus>();

  late final Account account;
  final mobx.Observable<User?> _currentUser = mobx.Observable<User?>(null, name: 'contador');
  late final mobx.ObservableStream<AuthStatus> _status;

  // Getter methods
  User? get currentUser => _currentUser.value;
  AuthStatus? get status => _status.value;
  String? get username => _currentUser.name;
  String? get email => _currentUser.value?.email;
  String? get userid => _currentUser.value?.$id;
  StreamSubscription<AuthStatus>? statusSubscription;

  void addStatusListener(void Function(AuthStatus)? callback) {
    statusSubscription = _status.listen(callback);
  }

  void removeStatusListener(void Function(AuthStatus)? callback) {
    statusSubscription?.cancel();
  }

  // Initialize the Appwrite client
  void init() {
    account = Account(Core.client);
  }

  late final loadUser = mobx.Action(_loadUser, name: 'loadUser');
  late final createUser = mobx.Action(_createUser, name: 'createUser');
  late final createEmailPasswordSession = mobx.Action(_createEmailPasswordSession, name: 'createEmailPasswordSession');
  late final signInWithProvider = mobx.Action(_signInWithProvider, name: 'signInWithProvider');
  late final signOut = mobx.Action(_signOut, name: 'signOut');

  Future<void> _loadUser() async {
    try {
      final user = await account.get();
      _statusStreamController.add(AuthStatus.authenticated);
      _currentUser.value = user;
    } catch (e) {
      _statusStreamController.add(AuthStatus.unauthenticated);
    }
  }

  Future<User> _createUser({
    required String email,
    required String password,
  }) async {
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: 'Simon G',
    );
    return user;
  }

  Future<Session> _createEmailPasswordSession({
    required String email,
    required String password,
  }) async {
    final session =
        await account.createEmailPasswordSession(email: email, password: password);
    _currentUser.value = await account.get();
    _statusStreamController.add(AuthStatus.authenticated);
    return session;
  }

  Future<dynamic> _signInWithProvider({required OAuthProvider provider}) async {
    final dynamic session = await account.createOAuth2Session(provider: provider);
    _currentUser.value = await account.get();
    _statusStreamController.add(AuthStatus.authenticated);
    return session;
  }

  Future<void> _signOut() async {
    await account.deleteSession(sessionId: 'current');
    _statusStreamController.add(AuthStatus.unauthenticated);
  }

  Future<Preferences> getUserPreferences() async {
    return await account.getPrefs();
  }

  Future<User> updatePreferences({required String bio}) async {
    return account.updatePrefs(prefs: {'bio': bio});
  }

  void checkAuthentication(String currentUri) {
    final prevRouteIsLoginOrRoot = currentUri.compareTo(routePaths.login) == 0 || currentUri.compareTo(routePaths.path) == 0;

    if (_status.value != AuthStatus.authenticated && currentUri.compareTo(routePaths.login) != 0) {
      Routefly.navigate(routePaths.login);
    }

    if (_status.value == AuthStatus.authenticated && prevRouteIsLoginOrRoot) {
      Routefly.navigate(routePaths.home);
    }
  }
}
