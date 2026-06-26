import 'package:flutter/material.dart';
import 'measurement_view_model.dart';
import 'auth_page.dart';
import 'history_page.dart';
import 'api_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676), 
          secondary: Color(0xFF2979FF), 
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF00E676),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();
  String _connectedUser = "Utilisateur";
  final MeasurementViewModel _viewModel = MeasurementViewModel();

  @override
  Widget build(BuildContext context) {
    final Widget profileTab = _apiClient.isAuthenticated
        ? Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E1E), Color(0xFF1A237E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00E676), width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 45,
                            backgroundColor: Color(0xFF263238),
                            child: Icon(Icons.person, size: 55, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _connectedUser,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          backgroundColor: const Color(0xFF00E676).withOpacity(0.15),
                          side: BorderSide.none,
                          label: const Text(
                            "COMPTE CLOUD ACTIF",
                            style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: const Color(0xFF1E1E1E),
                          elevation: 0,
                          child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Icon(Icons.cloud_done_outlined, color: Color(0xFF2979FF), size: 32),
                                SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Accès Multi-Plateforme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      SizedBox(height: 6),
                                      Text("Vos mesures sont synchronisées et restent accessibles en temps réel depuis n'importe quel autre appareil.", style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                          label: const Text("Se déconnecter", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _apiClient.clearAuthToken();
                              _viewModel.logout();
                              _currentIndex = 0;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Déconnexion réussie")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : AuthPage(
            onAuthSuccess: (username) {
              setState(() {
                _connectedUser = username;
                _currentIndex = 0;
              });
            },
          );

    final List<Widget> pages = [
      const Scaffold(body: MeasurementWidget()),
      const HistoryPage(),
      profileTab,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text("QoE ESTIMATOR"),
          ],
        ),
        actions: [
          if (_apiClient.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 22),
              onPressed: () {
                setState(() {
                  _apiClient.clearAuthToken();
                  _viewModel.logout();
                  _currentIndex = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Déconnecté avec succès")),
                );
              },
            ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Mesurer"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Historique"),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint_rounded), label: "Profil"),
        ],
      ),
    );
  }
}

class MeasurementWidget extends StatefulWidget {
  const MeasurementWidget({super.key});

  @override
  State<MeasurementWidget> createState() => _MeasurementWidgetState();
}

class _MeasurementWidgetState extends State<MeasurementWidget> {
  final ApiClient _apiClient = ApiClient();
  final MeasurementViewModel viewModel = MeasurementViewModel();
  int _selectedMode = 0;

  final _throughputController = TextEditingController();
  final _delayController = TextEditingController();
  final _jitterController = TextEditingController();
  final _lossController = TextEditingController();
  final _bitrateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_onViewModelUpdate);
  }

  void _onViewModelUpdate() {
    if (mounted) {
      setState(() {}); // Rafraîchit l'interface dès que le ViewModel change d'état
    }
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelUpdate);
    _throughputController.dispose();
    _delayController.dispose();
    _jitterController.dispose();
    _lossController.dispose();
    _bitrateController.dispose();
    super.dispose();
  }

  void _triggerManualEvaluation() {
    final t = double.tryParse(_throughputController.text.trim()) ?? -1;
    final d = double.tryParse(_delayController.text.trim()) ?? -1;
    final j = double.tryParse(_jitterController.text.trim()) ?? -1;
    final l = double.tryParse(_lossController.text.trim()) ?? -1;
    final b = double.tryParse(_bitrateController.text.trim()) ?? -1;

    if (t < 0 || d < 0 || j < 0 || l < 0 || b < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir des valeurs valides supérieures ou égales à 0.")),
      );
      return;
    }

    final Map<String, double> metrics = {
      'throughput': t,
      'delay_qos': d,
      'jitter': j,
      'packet_loss': l,
      'avg_bitrate': b,
    };

    viewModel.submitManualMetrics(metrics);
  }

void _resetFormAndResult() {
    setState(() {
      _throughputController.clear();
      _delayController.clear();
      _jitterController.clear();
      _lossController.clear();
      _bitrateController.clear();
      
      // CORRIGÉ : On appelle resetValues() pour ne pas te déconnecter !
      viewModel.resetValues(); 
    });
  }

  Widget _buildManualField(TextEditingController controller, String label, IconData icon, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2979FF), size: 20),
          suffixText: unit,
          suffixStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _apiClient.isAuthenticated;
    final bool hasResult = viewModel.mosScore != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Commutateur masqué si un résultat ou un chargement est en cours
          if (isConnected && !hasResult && !viewModel.isLoading) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMode == 0 ? const Color(0xFF263238) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, size: 18, color: _selectedMode == 0 ? const Color(0xFF00E676) : Colors.grey),
                            const SizedBox(width: 6),
                            Text("Auto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _selectedMode == 0 ? Colors.white : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMode == 1 ? const Color(0xFF263238) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded, size: 18, color: _selectedMode == 1 ? const Color(0xFF2979FF) : Colors.grey),
                            const SizedBox(width: 6),
                            Text("Formulaire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _selectedMode == 1 ? Colors.white : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ZONE CENTRALE RECONFIGURABLE
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Formulaire de saisie manuel (seulement si connecté, mode formulaire sélectionné, pas de chargement et pas de résultat)
                    if (isConnected && _selectedMode == 1 && !viewModel.isLoading && !hasResult) ...[
                      const Text(
                        "MÉTRIQUES DE FLUX RÉSEAU",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 15),
                      _buildManualField(_throughputController, "Débit descendant (Throughput)", Icons.speed_rounded, "Mbps"),
                      _buildManualField(_delayController, "Latence QoS (Delay)", Icons.hourglass_bottom_rounded, "ms"),
                      _buildManualField(_jitterController, "Jitter", Icons.waves_rounded, "ms"),
                      _buildManualField(_lossController, "Perte de Paquets", Icons.running_with_errors_rounded, "%"),
                      _buildManualField(_bitrateController, "Bitrate Moyen (Avg Bitrate)", Icons.equalizer_rounded, "kbps"),
                    ] 
                    // Magnifique Cercle d'Origine (Pour Mode Auto, Chargement, Résultat Final ou Erreur)
                    else ...[
                      Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: viewModel.isLoading 
                                ? const Color(0xFF2979FF) 
                                : (hasResult ? const Color(0xFF00E676) : const Color(0xFF1E1E1E)),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (viewModel.isLoading) ...[
                              const Icon(Icons.cloud_sync_rounded, size: 55, color: Color(0xFF2979FF)),
                              const SizedBox(height: 15),
                              const Text(
                                "Analyse IA des performances cloud en cours...",
                                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ] else if (hasResult) ...[
                              const Text("SCORE MOS", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text(
                                viewModel.mosScore!.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF00E676), fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Qualité réseau : ${viewModel.niveauQualite}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                viewModel.sauvegarde ? "Sauvegardé et synchronisé sur votre espace Cloud" : "Sauvegardé localement sur cet appareil",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                              ),
                            ] else if (viewModel.errorMessage != null) ...[
                              const Icon(Icons.error_outline_rounded, size: 55, color: Colors.redAccent),
                              const SizedBox(height: 15),
                              Text(
                                "Erreur: ${viewModel.errorMessage}",
                                style: const TextStyle(fontSize: 13, color: Colors.redAccent, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              const Icon(Icons.speed_rounded, size: 55, color: Color(0xFF00E676)),
                              const SizedBox(height: 15),
                              const Text(
                                "Prêt à évaluer vos performances réseau",
                                style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // BOUTONS DE COMMANDE RECONFIGURABLES
          if (viewModel.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (hasResult)
            ElevatedButton.icon(
              onPressed: _resetFormAndResult, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF263238),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text("FAIRE UNE NOUVELLE ESTIMATION", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(
              onPressed: (isConnected && _selectedMode == 1) ? _triggerManualEvaluation : () => viewModel.startMeasurement(),
              style: ElevatedButton.styleFrom(
                backgroundColor: (isConnected && _selectedMode == 1) ? const Color(0xFF2979FF) : const Color(0xFF00E676),
                foregroundColor: (isConnected && _selectedMode == 1) ? Colors.white : Colors.black,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon((isConnected && _selectedMode == 1) ? Icons.analytics_rounded : Icons.play_arrow_rounded, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    (isConnected && _selectedMode == 1) ? "CALCULER LE SCORE IA" : "LANCER L'ÉVALUATION", 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}