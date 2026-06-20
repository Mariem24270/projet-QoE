import 'package:flutter/material.dart';
import 'network_test_service.dart';
import 'api_client.dart';

class MeasurementViewModel extends ChangeNotifier {
  final NetworkTestService _testService = NetworkTestService();
  final ApiClient _apiClient = ApiClient();

  bool isLoading = false;
  double? mosScore;
  String? errorMessage;

  Future<void> startMeasurement() async {
    isLoading = true;
    mosScore = null;
    errorMessage = null;
    notifyListeners();

    try {
      final metrics = await _testService.runFullNetworkTest();
      final score = await _apiClient.sendMetricsToBackend(metrics.toJson());
      mosScore = score;
    } catch (e) {
      errorMessage = e.toString();
      mosScore = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}