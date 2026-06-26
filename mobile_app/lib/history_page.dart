import 'package:flutter/material.dart';
import 'api_client.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Stream<List<dynamic>> _historyStream() async* {
    final ApiClient apiClient = ApiClient();
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        yield await apiClient.fetchHistory();
      } catch (e) {
        yield [];
      }
    }
  }

  // Fonction utilitaire pour formater proprement la date ISO-8601 reçue
  String _formatDate(String? dateRaw) {
    if (dateRaw == null || dateRaw.isEmpty) return "Date inconnue";
    try {
      final dateTime = DateTime.parse(dateRaw).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return "$day/$month/$year à ${hour}h$minute";
    } catch (_) {
      return "Date inconnue";
    }
  }

  void _showMeasureDetails(BuildContext context, dynamic measure) {
    // Extraction automatique de la date (s'adapte au local 'mesure_le' ou à un champ Django 'mesure_le'/'date')
    final String dateRaw = measure['mesure_le'] ?? measure['date'] ?? '';
    final String dateFormatee = _formatDate(dateRaw);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Détails de la Mesure", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 15),
              _buildMetricRow(Icons.speed_rounded, "Débit (Throughput)", "${measure['throughput']} Mbps"),
              _buildMetricRow(Icons.hourglass_bottom_rounded, "Latence (Delay QoS)", "${measure['delay_qos']} ms"),
              _buildMetricRow(Icons.waves_rounded, "Jitter", "${measure['jitter']} ms"),
              _buildMetricRow(Icons.running_with_errors_rounded, "Perte de Paquets", "${measure['packet_loss']} %"),
              _buildMetricRow(Icons.equalizer_rounded, "Bitrate Moyen", "${measure['avg_bitrate']} kbps"),
              _buildMetricRow(Icons.access_time_rounded, "Date de mesure", dateFormatee),
              const SizedBox(height: 15),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Score d'Évaluation :", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    "MOS ${measure['score_qoe']?.toStringAsFixed(2) ?? 'N/A'}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E676), fontFamily: 'monospace'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2979FF)),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = ApiClient();
    final bool isAuthed = apiClient.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAuthed ? "ESPACE DE STOCKAGE CLOUD" : "STOCKAGE LOCAL APPAREIL"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _historyStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur de flux : ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          
          final List<dynamic>? measures = snapshot.data;
          if (measures == null || measures.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear_outlined, size: 45, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    "Aucune mesure enregistrée.\nLancez un test pour alimenter l'historique.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: measures.length,
            itemBuilder: (context, index) {
              final measure = measures[index];

              // Récupération et formatage de la date de la mesure actuelle
              final String dateRaw = measure['mesure_le'] ?? measure['date'] ?? '';
              final String dateFormatee = _formatDate(dateRaw);

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: ListTile(
                  onTap: () => _showMeasureDetails(context, measure),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${measure['score_qoe']?.toStringAsFixed(1) ?? 'N/A'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676), fontSize: 15, fontFamily: 'monospace'),
                    ),
                  ),
                  title: Text(
                    "Qualité : ${measure['niveau_qualite'] ?? 'Inconnue'}",
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Débit : ${measure['throughput']} Mbps",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatee,
                              style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ),
              );
            },
          );
        },
      ),
    );
  }
}