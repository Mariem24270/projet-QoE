import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> register(String username, String email, String password) async {
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
      } else {
        throw Exception("Compte créé, mais aucun jeton d'accès reçu.");
      }
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

  Future<List<dynamic>> fetchHistory() async {
    if (isAuthenticated) {
      try {
        final response = await _dio.get('$baseUrl/api/historique/');
        return response.data as List<dynamic>;
      } on DioException catch (e) {
        throw Exception("Erreur historique cloud : ${e.message}");
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getStringList('local_measures') ?? [];
      return localData.map((item) => jsonDecode(item)).toList().reversed.toList();
    }
  }

  Future<void> saveMeasureLocally(Map<String, dynamic> metrics, double mos, String qe) async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getStringList('local_measures') ?? [];
    
    final newMeasure = {
      'score_qoe': mos,
      'niveau_qualite': qe,
      'throughput': metrics['throughput'] ?? 0.0,
      'delay_qos': metrics['delay_qos'] ?? 0.0,
      'jitter': metrics['jitter'] ?? 0.0,               
      'packet_loss': metrics['packet_loss'] ?? 0.0,      
      'avg_bitrate': metrics['avg_bitrate'] ?? 0.0,       
      'mesure_le': DateTime.now().toIso8601String(),
    };
    
    localData.add(jsonEncode(newMeasure));
    await prefs.setStringList('local_measures', localData);
  }

  Future<Map<String, dynamic>> sendMetricsToBackend(Map<String, dynamic> metrics) async {
    try {
      final response = await _dio.post('$baseUrl/api/predict/', data: metrics);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        
        final double mos = data['score_qoe']?.toDouble() ?? 0.0;
        final String qe = data['niveau_qualite'] ?? '';
        final bool saved = data['sauvegarde'] ?? false;

        if (!saved) {
          await saveMeasureLocally(metrics, mos, qe);
        }

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