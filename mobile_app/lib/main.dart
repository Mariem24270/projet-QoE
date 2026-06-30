import 'package:flutter/material.dart';
import 'measurement_view_model.dart';
import 'auth_page.dart';
import 'history_page.dart';
import 'auth/auth_controller.dart';

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
  final AuthController _auth = AuthController();
  final MeasurementViewModel _viewModel = MeasurementViewModel();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    // Restaure une session existante (rester connecté entre deux lancements).
    _auth.restoreSession();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      // Les onglets « Historique » et « Profil » disparaissent à la
      // déconnexion ; on revient alors à « Mesurer ».
      final int tabCount = _auth.isAuthenticated ? 3 : 1;
      if (_currentIndex >= tabCount) _currentIndex = 0;
    });
  }

  Future<void> _openAuthPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen(initialRegisterMode: true)),
    );
    if (mounted && _auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bienvenue, ${_auth.displayName} !")),
      );
    }
  }

  Future<void> _handleLogout() async {
    await _auth.logout();
    _viewModel.resetValues();
    if (mounted) {
      setState(() => _currentIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Déconnexion réussie")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget profileTab = _auth.isAuthenticated
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
                          _auth.displayName,
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
                          onPressed: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    // Pages alignées sur les onglets : « Historique » et « Profil »
    // n'existent qu'une fois l'utilisateur authentifié, car l'historique
    // est stocké exclusivement dans le cloud (aucune donnée locale).
    final List<Widget> pages = [
      const Scaffold(body: MeasurementWidget()),
      if (_auth.isAuthenticated) const HistoryPage(),
      if (_auth.isAuthenticated) profileTab,
    ];

    // Onglets de navigation : « Historique » et « Profil » apparaissent
    // uniquement après connexion.
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Mesurer"),
      if (_auth.isAuthenticated)
        const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Historique"),
      if (_auth.isAuthenticated)
        const BottomNavigationBarItem(icon: Icon(Icons.fingerprint_rounded), label: "Profil"),
    ];

    final int safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text("QoE ESTIMATOR"),
          ],
        ),
        actions: [
          if (_auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 22),
              tooltip: "Se déconnecter",
              onPressed: _handleLogout,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                style: ButtonStyle(
                  // Vert principal de l'application, harmonisé avec le logo et
                  // le bouton « LANCER L'ÉVALUATION », y compris hover/focus/active.
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return const Color(0xFF00C853); // vert plus profond (active)
                    }
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)) {
                      return const Color(0xFF1DE786); // vert plus clair (hover/focus)
                    }
                    return const Color(0xFF00E676); // vert principal (repos)
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.black),
                  overlayColor: WidgetStatePropertyAll(
                    const Color(0xFF00E676).withOpacity(0.15),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 14),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  "Se connecter",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _openAuthPage,
              ),
            ),
        ],
      ),
      body: pages[safeIndex],
      // Apparition/disparition fluide de la barre lorsqu'un onglet est ajouté.
      bottomNavigationBar: navItems.length >= 2
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => SizeTransition(
                sizeFactor: anim,
                axisAlignment: -1,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: BottomNavigationBar(
                key: ValueKey(navItems.length),
                currentIndex: safeIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) => setState(() => _currentIndex = index),
                items: navItems,
              ),
            )
          : null,
    );
  }
}

class MeasurementWidget extends StatefulWidget {
  const MeasurementWidget({super.key});

  @override
  State<MeasurementWidget> createState() => _MeasurementWidgetState();
}

class _MeasurementWidgetState extends State<MeasurementWidget> {
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
      setState(() {}); 
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
    final bool hasResult = viewModel.mosScore != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // MODIFIÉ : Le commutateur s'affiche désormais même sans connexion
          if (!hasResult && !viewModel.isLoading) ...[
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
                    // MODIFIÉ : Retrait de la condition "isConnected" pour afficher le formulaire
                    if (_selectedMode == 1 && !viewModel.isLoading && !hasResult) ...[
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
                                viewModel.sauvegarde ? "Sauvegardé et synchronisé sur votre espace Cloud" : "Connectez-vous pour sauvegarder cette mesure dans le cloud",
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
              // MODIFIÉ : Le comportement du bouton principal dépend désormais uniquement du mode sélectionné
              onPressed: _selectedMode == 1 ? _triggerManualEvaluation : () => viewModel.startMeasurement(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedMode == 1 ? const Color(0xFF2979FF) : const Color(0xFF00E676),
                foregroundColor: _selectedMode == 1 ? Colors.white : Colors.black,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_selectedMode == 1 ? Icons.analytics_rounded : Icons.play_arrow_rounded, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    _selectedMode == 1 ? "CALCULER LE SCORE IA" : "LANCER L'ÉVALUATION", 
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