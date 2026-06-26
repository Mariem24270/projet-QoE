import 'package:flutter/material.dart';
import 'api_client.dart';

class AuthPage extends StatefulWidget {
  final Function(String username) onAuthSuccess;
  const AuthPage({super.key, required this.onAuthSuccess});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final ApiClient _apiClient = ApiClient();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoginMode = true;
  bool isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.2), width: 1),
                ),
                // CORRIGÉ : Utilisation d'une icône existante officielle de Flutter
                child: const Icon(Icons.lock_person_outlined, size: 55, color: Color(0xFF2979FF)),
              ),
              const SizedBox(height: 20),
              Text(
                isLoginMode ? "Accéder à l'Espace Cloud" : "Créer un Compte Synchronisé", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Vos données de test sont toujours enregistrées. Connectez-vous simplement pour les rendre accessibles en temps réel depuis plusieurs endroits différents.",
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 35),
              TextField(
                controller: _usernameController, 
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                  labelText: "Nom d'utilisateur ou Email", 
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5)),
                ),
              ),
              if (!isLoginMode) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController, 
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey, size: 20),
                    labelText: "Adresse Email", 
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5)),
                  ),
                ),
              ],
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController, 
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                  labelText: "Mot de passe", 
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5)),
                ),
              ),
              const SizedBox(height: 35),
              isLoading 
                ? const CircularProgressIndicator(strokeWidth: 2.5)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final String userText = _usernameController.text.trim();
                      if (userText.isEmpty || _passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires.")),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        if (isLoginMode) {
                          await _apiClient.login(userText, _passwordController.text.trim());
                        } else {
                          if (_emailController.text.trim().isEmpty) {
                            throw Exception("L'adresse email est requise.");
                          }
                          await _apiClient.register(userText, _emailController.text.trim(), _passwordController.text.trim());
                        }
                        
                        final String cleanName = userText.split('@')[0];
                        widget.onAuthSuccess(cleanName);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
                          );
                        }
                      } finally { // CORRIGÉ : Changement du mot clé erroné par 'finally'
                        if (mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
                    child: Text(isLoginMode ? "SE CONNECTER" : "CRÉER MON ESPACE", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => setState(() => isLoginMode = !isLoginMode),
                child: Text(
                  isLoginMode ? "Créer un compte synchronisé" : "Déjà membre ? Se connecter",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}