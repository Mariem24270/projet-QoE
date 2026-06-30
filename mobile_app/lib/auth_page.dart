import 'package:flutter/material.dart';
import 'auth/auth_controller.dart';

/// Écran d'authentification autonome (ouvert depuis le bouton « Créer un
/// compte » du tableau de bord). Fournit la structure de page (AppBar + retour)
/// tout en réutilisant le widget [AuthPage] dont l'architecture visuelle reste
/// strictement inchangée.
class AuthScreen extends StatelessWidget {
  final bool initialRegisterMode;
  const AuthScreen({super.key, this.initialRegisterMode = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: AuthPage(
        initialRegisterMode: initialRegisterMode,
        onAuthSuccess: (_) => Navigator.of(context).pop(),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  final Function(String username) onAuthSuccess;
  final bool initialRegisterMode;
  const AuthPage({
    super.key,
    required this.onAuthSuccess,
    this.initialRegisterMode = false,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final AuthController _auth = AuthController();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late bool isLoginMode;
  bool isLoading = false;
  bool _obscurePassword = true;
  String? _serverError;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  static const Color _accentBlue = Color(0xFF2979FF);
  static const Color _surface = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    isLoginMode = !widget.initialRegisterMode;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      _serverError = null;
      _formKey.currentState?.reset();
    });
  }

  // ---- Validateurs élégants -------------------------------------------------

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Ce champ est obligatoire.";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "L'adresse email est requise.";
    final emailRegex = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$');
    if (!emailRegex.hasMatch(v)) return "Adresse email invalide.";
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return "Le mot de passe est obligatoire.";
    if (!isLoginMode && v.length < 6) {
      return "6 caractères minimum.";
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (isLoginMode) return null;
    if ((value ?? '') != _passwordController.text) {
      return "Les mots de passe ne correspondent pas.";
    }
    return null;
  }

  // ---- Soumission -----------------------------------------------------------

  Future<void> _submit() async {
    setState(() => _serverError = null);
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      if (isLoginMode) {
        await _auth.login(
          identifier: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _auth.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) widget.onAuthSuccess(_auth.displayName);
    } catch (e) {
      if (mounted) {
        setState(() => _serverError = e.toString().replaceAll("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---- Helpers de style (identiques à l'interface d'origine) ----------------

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      labelText: label,
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  /// Conteneur animé : déploie/replie en douceur les champs propres au mode
  /// inscription (email, confirmation) lors du changement de mode.
  Widget _expandable({required bool visible, required Widget child}) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: visible ? 1 : 0,
        child: visible ? child : const SizedBox(width: double.infinity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentBlue.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.lock_person_outlined, size: 55, color: _accentBlue),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      isLoginMode ? "Accéder à l'Espace Cloud" : "Créer un Compte Synchronisé",
                      key: ValueKey(isLoginMode),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Vos données de test sont toujours enregistrées. Connectez-vous simplement pour les rendre accessibles en temps réel depuis plusieurs endroits différents.",
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),

                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    validator: _validateIdentifier,
                    decoration: _fieldDecoration(
                      label: "Nom d'utilisateur ou Email",
                      icon: Icons.person_outline,
                    ),
                  ),

                  // Champ Email — uniquement en mode inscription (animé).
                  _expandable(
                    visible: !isLoginMode,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: isLoginMode ? null : _validateEmail,
                          decoration: _fieldDecoration(
                            label: "Adresse Email",
                            icon: Icons.mail_outline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: isLoginMode ? TextInputAction.done : TextInputAction.next,
                    validator: _validatePassword,
                    decoration: _fieldDecoration(
                      label: "Mot de passe",
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  // Champ Confirmation — uniquement en mode inscription (animé).
                  _expandable(
                    visible: !isLoginMode,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirm,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: _fieldDecoration(
                            label: "Confirmer le mot de passe",
                            icon: Icons.lock_reset_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Message d'erreur serveur élégant (animé).
                  _expandable(
                    visible: _serverError != null,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _serverError ?? '',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : ElevatedButton(
                            key: const ValueKey('submit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _submit,
                            child: Text(
                              isLoginMode ? "SE CONNECTER" : "CRÉER MON ESPACE",
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: isLoading ? null : _toggleMode,
                    child: Text(
                      isLoginMode ? "Créer un compte synchronisé" : "Déjà membre ? Se connecter",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
