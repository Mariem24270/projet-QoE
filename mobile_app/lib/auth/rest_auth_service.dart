import '../api_client.dart';
import 'auth_service.dart';

/// Implémentation de [AuthService] basée sur l'API REST actuelle
/// (backend Django). Réutilise [ApiClient] pour les appels HTTP.
///
/// Toute la logique réseau reste isolée ici : remplacer ce service
/// par une implémentation Firebase ou Laravel n'impacte ni l'UI ni la
/// gestion de session.
class RestAuthService implements AuthService {
  final ApiClient _apiClient;

  RestAuthService([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final token = await _apiClient.register(username, email, password);
    return AuthUser(username: username, email: email, token: token);
  }

  @override
  Future<AuthUser> login({
    required String identifier,
    required String password,
  }) async {
    final token = await _apiClient.login(identifier, password);
    final bool isEmail = identifier.contains('@');
    return AuthUser(
      username: isEmail ? identifier.split('@').first : identifier,
      email: isEmail ? identifier : null,
      token: token,
    );
  }

  @override
  Future<void> logout() async {
    _apiClient.clearAuthToken();
  }
}
