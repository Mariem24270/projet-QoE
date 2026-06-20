import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String apiUrl = "http://localhost:3000";

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<double> sendMetricsToBackend(Map<String, dynamic> metrics) async {
    try {
      final response = await _dio.post(apiUrl, data: metrics);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        if (response.data is String) {
          responseData = Map<String, dynamic>.from(response.data);
        } else {
          responseData = response.data as Map<String, dynamic>;
        }
        return responseData['mos']?.toDouble() ?? 0.0;
      } else {
        throw Exception("Échec de la réponse du serveur (code : ${response.statusCode})");
      }
    } on DioException catch (e) {
      throw Exception("Erreur de connexion au serveur : ${e.message}");
    } catch (e) {
      throw Exception("Une erreur inattendue s'est produite : $e");
    }
  }
}