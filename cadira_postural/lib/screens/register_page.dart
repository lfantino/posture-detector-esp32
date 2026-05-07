import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;
    final email    = "$username@app.com";

    // ── Validació ──────────────────────────────────────────────────────────
    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() { _errorMessage = 'Omple tots els camps.'; _successMessage = null; });
      return;
    }
    if (password.length < 6) {
      setState(() { _errorMessage = 'La contrasenya ha de tenir mínim 6 caràcters.'; _successMessage = null; });
      return;
    }
    if (password != confirm) {
      setState(() { _errorMessage = 'Les contrasenyes no coincideixen.'; _successMessage = null; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    final db = DatabaseHelper();
    String? error;
    try {
      error = await db.registrarUsuari(
        username: username,
        email: email,
        password: password,
      );
    } catch (e) {
      error = "S'ha produït un error inesperat: $e";
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      setState(() => _successMessage = 'Compte creat correctament! Ja pots iniciar sessió.');
      // Tornar al login després de 2 segons
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.arrow_back, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Torna al login', style: TextStyle(color: Colors.grey, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 28),
              const Text('Crea un compte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1D2E))),
              const SizedBox(height: 6),
              const Text("Registra't per accedir a SensorFlow", style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      )
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nom d'usuari ─────────────────────────────────────────
                    const Text("Nom d'usuari", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: "El teu nom d'usuari",
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                        filled: true, fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),



                    // ── Contrasenya ──────────────────────────────────────────
                    const Text('Contrasenya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Mínim 6 caràcters',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true, fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Confirmar contrasenya ────────────────────────────────
                    const Text('Confirma la contrasenya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Repeteix la contrasenya',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        filled: true, fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Missatge d'error ─────────────────────────────────────
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Missatge d'èxit ──────────────────────────────────────
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF43A047), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_successMessage!, style: const TextStyle(color: Color(0xFF43A047), fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Botó registrar ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB5A1E5), foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text("Registra't", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
