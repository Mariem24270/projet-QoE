import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_client.dart';
import 'auth_service.dart';
import 'rest_auth_service.dart';

/// Gestionnaire central de session et d'authentification.
///
/// - Expose l'état d'authentification de façon réactive ([ChangeNotifier]).
/// - Persiste la session sur l'appareil ([SharedPreferences]) afin de
///   rester connecté entre deux lancements de l'application.
/// - Délègue les appels réseau à un [AuthService] interchangeable, ce qui
///   permet de basculer vers Laravel / Firebase / autre API sans toucher
///   à l'interface.
class AuthController extends ChangeNotifier {
  AuthController._internal();
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  static const String _storageKey = 'auth_session';

  /// Service d'authentification courant (REST par défaut).
  /// Remplaçable à chaud pour brancher un autre backend.
  AuthService _service = RestAuthService();
  void useService(AuthService service) => _service = service;

  final ApiClient _apiClient = ApiClient();

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String get displayName => _currentUser?.username ?? 'Utilisateur';

  /// Restaure une éventuelle session sauvegardée au démarrage.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _currentUser = user;
      _apiClient.setAuthToken(user.token);
      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final user = await _service.register(
      username: username,
      email: email,
      password: password,
    );
    await _persist(user);
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final user = await _service.login(
      identifier: identifier,
      password: password,
    );
    await _persist(user);
  }

  Future<void> logout() async {
    await _service.logout();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _persist(AuthUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(user.toJson()));
    notifyListeners();
  }
}
