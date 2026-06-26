import 'package:flutter/material.dart';
import 'network_test_service.dart';
import 'api_client.dart';

class MeasurementViewModel extends ChangeNotifier {
  static final MeasurementViewModel _instance = MeasurementViewModel._internal();
  factory MeasurementViewModel() => _instance;
  MeasurementViewModel._internal();

  final NetworkTestService _testService = NetworkTestService();
  final ApiClient _apiClient = ApiClient();

  bool isLoading = false;
  double? mosScore;
  String? niveauQualite;
  bool sauvegarde = false;
  String? errorMessage;

  void setAuthToken(String token) {
    _apiClient.setAuthToken(token);
    notifyListeners();
  }

  // Cette fonction ne sert QUE pour la déconnexion volontaire
  void logout() {
    _apiClient.clearAuthToken();
    resetValues();
  }

  // NOUVELLE FONCTION : Nettoie uniquement les scores sans déconnecter !
  void resetValues() {
    mosScore = null;
    niveauQualite = null;
    sauvegarde = false;
    errorMessage = null;
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
      final metrics = await _testService.runFullNetworkTest();
      final result = await _apiClient.sendMetricsToBackend(metrics.toJson());

      mosScore = result['mos'] != null ? (result['mos'] as num).toDouble() : null;
      niveauQualite = result['niveau_qualite'];
      sauvegarde = result['sauvegarde'] ?? false;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      mosScore = null;
      niveauQualite = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitManualMetrics(Map<String, double> manualMetrics) async {
    isLoading = true;
    mosScore = null;
    niveauQualite = null;
    errorMessage = null;
    sauvegarde = false;
    notifyListeners();

    try {
      final result = await _apiClient.sendMetricsToBackend(manualMetrics);

      mosScore = result['mos'] != null ? (result['mos'] as num).toDouble() : null;
      niveauQualite = result['niveau_qualite'];
      sauvegarde = result['sauvegarde'] ?? false;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      mosScore = null;
      niveauQualite = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}