import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String baseUrl = "http://127.0.0.1:8000";
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static String? _token;

  bool get isAuthenticated => _token != null;

  void setAuthToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  // INSCRIPTION + CONNEXION AUTOMATIQUE LIÉE
  Future<String> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('$baseUrl/api/inscription/', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      // Django renvoie déjà {"access": "..."} à l'inscription. On s'en sert !
      final token = response.data['access'];
      if (token != null) {
        setAuthToken(token);
        return token;
      }
      throw Exception("Compte créé, mais aucun jeton d'accès reçu.");
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(data.values.first is List ? data.values.first.first : data.values.first.toString());
      }
      throw Exception("Erreur inscription : ${e.message}");
    }
  }

  // CONNEXION CLASSIQUE
  Future<String> login(String username, String password) async {
    try {
      final response = await _dio.post('$baseUrl/api/login/', data: {
        'username': username,
        'password': password,
      });
      
      final token = response.data['token'] ?? response.data['access'];
      if (token != null) {
        setAuthToken(token);
        return token;
      }
      throw Exception("Token manquant dans la réponse du serveur");
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        throw Exception(e.response!.data['error'] ?? "Identifiants incorrects.");
      }
      throw Exception("Erreur de connexion.");
    }
  }

  /// Récupère l'historique des mesures depuis le cloud (par utilisateur).
  ///
  /// L'historique n'existe que pour un utilisateur authentifié : aucune
  /// donnée n'est conservée localement sur l'appareil. Sans session active,
  /// on renvoie une liste vide.
  Future<List<dynamic>> fetchHistory() async {
    if (!isAuthenticated) return [];
    try {
      final response = await _dio.get('$baseUrl/api/historique/');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception("Erreur historique cloud : ${e.message}");
    }
  }

  Future<Map<String, dynamic>> sendMetricsToBackend(Map<String, dynamic> metrics) async {
    try {
      final response = await _dio.post('$baseUrl/api/predict/', data: metrics);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        
        final double mos = data['score_qoe']?.toDouble() ?? 0.0;
        final String qe = data['niveau_qualite'] ?? '';
        // La sauvegarde est gérée exclusivement côté cloud : le backend
        // n'enregistre la mesure que si l'utilisateur est authentifié.
        final bool saved = data['sauvegarde'] ?? false;

        return {
          'mos': mos, 
          'niveau_qualite': qe, 
          'sauvegarde': saved,
          'throughput': metrics['throughput'],
          'delay_qos': metrics['delay_qos'],
          'jitter': metrics['jitter'],
          'packet_loss': metrics['packet_loss'],
          'avg_bitrate': metrics['avg_bitrate'],
        };
      }
      throw Exception("Erreur serveur");
    } on DioException catch (e) {
      throw Exception("Erreur réseau : ${e.message}");
    }
  }
}