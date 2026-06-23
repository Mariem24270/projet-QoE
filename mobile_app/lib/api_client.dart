import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();

  // URL correcte vers le backend Django de Mariem
  // En développement : utilise l'IP locale de la machine qui fait tourner Django
  // (pas localhost si l'app tourne sur un vrai téléphone — localhost sur mobile
  // pointe vers le téléphone lui-même, pas ton PC)
  final String baseUrl = "http://127.0.0.1:8000";

  // Appelée après le login pour que les mesures soient sauvegardées en base
  // Si pas appelée (utilisateur non connecté), la mesure est quand même
  // calculée et affichée mais pas sauvegardée (comportement voulu)
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Retire le token (utile au logout)
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> sendMetricsToBackend(
      Map<String, dynamic> metrics) async {
    try {
      // On envoie vers /api/predict/ (endpoint de prédiction du backend Django)
      final response =
          await _dio.post('$baseUrl/api/predict/', data: metrics);

      // Le backend renvoie 200 (non connecté) ou 201 (connecté + sauvegardé)
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
            response.data as Map<String, dynamic>;

        // Le backend renvoie "score_qoe" (pas "mos") et "niveau_qualite"
        return {
          'mos': data['score_qoe']?.toDouble() ?? 0.0,
          'niveau_qualite': data['niveau_qualite'] ?? '',
          'sauvegarde': data['sauvegarde'] ?? false,
        };
      } else {
        throw Exception(
            "Échec de la réponse du serveur (code : ${response.statusCode})");
      }
    } on DioException catch (e) {
      // Erreur réseau ou serveur non joignable
      if (e.response?.statusCode == 503) {
        throw Exception(
            "Le modèle IA n'est pas encore disponible sur le serveur.");
      }
      throw Exception("Erreur de connexion au serveur : ${e.message}");
    } catch (e) {
      throw Exception("Une erreur inattendue s'est produite : $e");
    }
  }
}