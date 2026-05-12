import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/user_session.dart';
import 'main_page.dart';
import 'register_page.dart';
import '../posture_control.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');

  @override
  void initState() {
    super.initState();
    _crearUsuariProva();
  }

  Future<void> _crearUsuariProva() async {
    final db = DatabaseHelper();
    // Intenta registrar l'usuari de prova. Si ja existeix, falla silenciosament.
    await db.registrarUsuari(
      username: 'admin',
      email: 'admin@prova.com',
      password: 'admin123',
      nomComplet: 'Usuari de Prova',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Omple tots els camps.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = DatabaseHelper();
    final usuari = await db.loginUsuari(username: username, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (usuari == null) {
      final database = await db.database;
      final verify = await database.query(
        DatabaseHelper.tableUsuaris,
        where: 'username = ?',
        whereArgs: [username.trim().toLowerCase()],
      );
      if (verify.isEmpty) {
        setState(() => _errorMessage = "Aquest usuari no existeix. Has de crear un compte (Registra't).");
      } else {
        setState(() => _errorMessage = "La contrasenya és incorrecta.");
      }
    } else {
      UserSession().setUser(usuari);
      
      // Carregar l'última calibració si n'hi ha
      final ultimaCalibracio = await db.obtenirUltimaCalibracio(usuari['id']);
      if (ultimaCalibracio != null) {
        PostureController.instance.loadThresholds(
          latCul: ultimaCalibracio['lat_cul'] as double,
          frontCul: ultimaCalibracio['front_cul'] as double,
          distCerv: ultimaCalibracio['dist_cerv'] as double,
          distTor: ultimaCalibracio['dist_tor'] as double,
          distLumb: ultimaCalibracio['dist_lumb'] as double,
          diffCervLumb: ultimaCalibracio['diff_cerv_lumb'] as double,
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/logo.png',
                width: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text('SpineApp',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
              const SizedBox(height: 8),
              const Text('Inicia sessió al teu compte',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
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
                    const Text('Usuari',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: "El teu nom d'usuari",
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Contrasenya',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'La teva contrasenya',
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),

                    // Missatge d'error
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFE53935), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB5A1E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Inicia sessió',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No estàs registrat? ",
                      style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage())),
                    child: const Text("Registra't",
                        style: TextStyle(
                            color: Color(0xFF8C82D6),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
