import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class LoginController {
  // Constructor
  LoginController() {
    init();
    loadUser();
    _status = mobx.ObservableStream<AuthStatus>(
      _statusStreamController.stream,
      name: 'status',
    );
  }

  late final StreamController<AuthStatus> _statusStreamController =
      StreamController<AuthStatus>();

  late final Account account;
  final mobx.Observable<User?> _currentUser = mobx.Observable<User?>(
    null,
    name: 'currentUser',
  );
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

  Future<void> loadUser() async {
    try {
      final user = await account.get();
      await Core.database.setSetting('cached_user_json', json.encode(user.toMap()));
      mobx.runInAction(() {
        _currentUser.value = user;
        _statusStreamController.add(AuthStatus.authenticated);
      });
    } catch (e) {
      final cachedJson = await Core.database.getSetting('cached_user_json');
      if (cachedJson != null) {
        try {
          final user = User.fromMap(
            json.decode(cachedJson) as Map<String, dynamic>,
          );
          mobx.runInAction(() {
            _currentUser.value = user;
            _statusStreamController.add(AuthStatus.authenticated);
          });
          return;
        } catch (_) {}
      }
      mobx.runInAction(() {
        _currentUser.value = null;
        _statusStreamController.add(AuthStatus.unauthenticated);
      });
    }
  }

  Future<User> createUser(String email, String password, String name) async {
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    return user;
  }

  Future<Session> createEmailPasswordSession(
    String email,
    String password,
  ) async {
    try {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final user = await account.get();
      await Core.database.setSetting('cached_user_json', json.encode(user.toMap()));
      mobx.runInAction(() {
        _currentUser.value = user;
        _statusStreamController.add(AuthStatus.authenticated);
      });
      return session;
    } on AppwriteException catch (e) {
      if (e.type == 'user_session_already_exists') {
        try {
          await account.deleteSession(sessionId: 'current');
        } catch (_) {}
        final session = await account.createEmailPasswordSession(
          email: email,
          password: password,
        );
        final user = await account.get();
        await Core.database.setSetting('cached_user_json', json.encode(user.toMap()));
        mobx.runInAction(() {
          _currentUser.value = user;
          _statusStreamController.add(AuthStatus.authenticated);
        });
        return session;
      }
      rethrow;
    }
  }

  Future<dynamic> signInWithProvider({required OAuthProvider provider}) async {
    final dynamic session = await account.createOAuth2Session(
      provider: provider,
    );
    final user = await account.get();
    await Core.database.setSetting('cached_user_json', json.encode(user.toMap()));
    mobx.runInAction(() {
      _currentUser.value = user;
      _statusStreamController.add(AuthStatus.authenticated);
    });
    return session;
  }

  Future<void> signOut() async {
    await Core.database.deleteSetting('cached_user_json');
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (_) {}
    Core.resetAllControllers();
    mobx.runInAction(() {
      _currentUser.value = null;
      _statusStreamController.add(AuthStatus.unauthenticated);
    });
  }

  Future<Preferences> getUserPreferences() async {
    return await account.getPrefs();
  }

  Future<User> updatePreferences({required String bio}) {
    return account.updatePrefs(prefs: {'bio': bio});
  }

  void checkAuthentication(String currentUri) {
    final prevRouteIsLoginOrRoot =
        currentUri.compareTo(routePaths.login) == 0 ||
        currentUri.compareTo(routePaths.path) == 0;

    if (_status.value != AuthStatus.authenticated &&
        currentUri.compareTo(routePaths.login) != 0) {
      Routefly.navigate(routePaths.login);
    }

    if (_status.value == AuthStatus.authenticated) {
      if (prevRouteIsLoginOrRoot) {
        Routefly.navigate(routePaths.capacitacao.path);
      }
    }
  }
}
