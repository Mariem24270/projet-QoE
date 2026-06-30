// Couche d'abstraction de l'authentification.
//
// Ce contrat permet de brancher n'importe quel fournisseur d'identité
// (API REST Django actuelle, Laravel, Firebase, etc.) sans modifier
// l'interface utilisateur ni la gestion de session.

/// Représente l'utilisateur authentifié et son jeton d'accès.
class AuthUser {
  final String username;
  final String? email;
  final String token;

  const AuthUser({
    required this.username,
    this.email,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'token': token,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        username: json['username'] as String,
        email: json['email'] as String?,
        token: json['token'] as String,
      );
}

/// Contrat commun à tous les fournisseurs d'authentification.
///
/// Pour brancher un autre backend, il suffit de créer une nouvelle
/// implémentation (ex. `FirebaseAuthService`, `LaravelAuthService`)
/// et de l'injecter dans le [AuthController] via `useService(...)`.
abstract class AuthService {
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
  });

  Future<AuthUser> login({
    required String identifier,
    required String password,
  });

  Future<void> logout();
}
