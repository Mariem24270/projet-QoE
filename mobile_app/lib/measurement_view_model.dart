import 'package:flutter/material.dart';
import 'network_test_service.dart';
import 'api_client.dart';

class MeasurementViewModel extends ChangeNotifier {
  final NetworkTestService _testService = NetworkTestService();
  final ApiClient _apiClient = ApiClient();

  bool isLoading = false;
  double? mosScore;
  String? niveauQualite;   // "Excellente", "Bonne", "Moyenne", "Faible", "Très faible"
  bool sauvegarde = false;  // true si l'utilisateur était connecté
  String? errorMessage;

  // Appelée depuis le widget de login une fois le token JWT récupéré
  void setAuthToken(String token) {
    _apiClient.setAuthToken(token);
  }

  // Appelée au logout
  void logout() {
    _apiClient.clearAuthToken();
    mosScore = null;
    niveauQualite = null;
    sauvegarde = false;
    notifyListeners();
  }

  Future<void> startMeasurement() async {
    isLoading = true;
    mosScore = null;
    niveauQualite = null;
    errorMessage = null;
    sauvegarde = false;
    notifyListeners();

    try {
      // 1. Mesurer les métriques réseau (throughput, delay_qos, jitter,
      //    packet_loss, avg_bitrate) — aucun changement ici
      final metrics = await _testService.runFullNetworkTest();

      // 2. Envoyer au backend Django et récupérer le score QoE
      final result = await _apiClient.sendMetricsToBackend(metrics.toJson());

      mosScore = result['mos'];
      niveauQualite = result['niveau_qualite'];
      sauvegarde = result['sauvegarde'] ?? false;

    } catch (e) {
      errorMessage = e.toString();
      mosScore = null;
      niveauQualite = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}