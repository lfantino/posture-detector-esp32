// Còpia del main.dart per poder veure com les llistes simulades es processen
// amb el posture_control.dart i modifiquen els widgets
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadira de Correcció Postural',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B5EFC)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ─── LOGIN ────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4B5EFC), Color(0xFF6B7FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.accessibility_new,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('SensorFlow',
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
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usuari',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "El teu nom d'usuari",
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Contrasenya',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v!),
                          shape: const CircleBorder(),
                          activeColor: const Color(0xFF4B5EFC),
                        ),
                        const Text("Recorda'm"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MainPage())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B5EFC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Inicia sessió',
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
                            color: Color(0xFF4B5EFC),
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

// ─── REGISTRE ─────────────────────────────────────────────────────────────────

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
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
                  Text('Torna al login',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 28),
              const Text('Crea un compte',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
              const SizedBox(height: 6),
              const Text("Registra't per accedir a SensorFlow",
                  style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Nom d'usuari",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                        decoration: InputDecoration(
                            hintText: "El teu nom d'usuari",
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none))),
                    const SizedBox(height: 20),
                    const Text('Correu electrònic',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                        decoration: InputDecoration(
                            hintText: 'correu@exemple.com',
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none))),
                    const SizedBox(height: 20),
                    const Text('Contrasenya',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Mínim 6 caràcters',
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                            icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Confirma la contrasenya',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Repeteix la contrasenya',
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                            icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B5EFC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: const Text("Registra't",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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

// ─── MAIN PAGE (navegació inferior) ──────────────────────────────────────────

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    EstadistiquesPage(),
    CalibracionPage(),
    ConfiguracioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF4B5EFC),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Estadístiques'),
          BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Calibració'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Configuració'),
        ],
      ),
    );
  }
}

// ─── DASHBOARD ────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showAlert = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avui, dissabte, 11 d\'abril',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Benvingut de nou, ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1D2E))),
                        TextSpan(
                            text: 'Usuari ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5EFC))),
                        TextSpan(text: '👋', style: TextStyle(fontSize: 20)),
                      ])),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.grey),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle)),
                      ),
                    ],
                  ),
                ],
              ),
              if (_showAlert) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE082))),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF8F00), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Porta 1h 23m assegut!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B5E00),
                                    fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Et recomanem fer una pausa i estirar-te.',
                                style: TextStyle(
                                    color: Color(0xFFAD7E00), fontSize: 13)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showAlert = false),
                        child: const Icon(Icons.close,
                            color: Color(0xFFAD7E00), size: 20),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Postura actual',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('2/3 sensors correctes',
                              style: TextStyle(
                                  color: Color(0xFF8B5E00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _sensorRow('Cervical', '✓ 5°', true),
                              const SizedBox(height: 16),
                              _sensorRow('Toràcic', '△ 18°', false),
                              const SizedBox(height: 16),
                              _sensorRow('Lumbar', '✓ 8°', true),
                              const SizedBox(height: 12),
                              const Row(children: [
                                Icon(Icons.circle,
                                    color: Colors.green, size: 10),
                                SizedBox(width: 4),
                                Text('Correcte',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                                SizedBox(width: 12),
                                Icon(Icons.circle, color: Colors.red, size: 10),
                                SizedBox(width: 4),
                                Text('Alerta',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Avui',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                        value: 0.78,
                                        strokeWidth: 10,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.green)),
                                    const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('78%',
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green)),
                                        Text('bona postura',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Temps assegut',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                              const Text('1h 23m',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard(Icons.access_time, '1h 23m', 'Temps actiu',
                      const Color(0xFFE8F0FE), const Color(0xFF4B5EFC)),
                  const SizedBox(width: 12),
                  _statCard(Icons.trending_up, '12', 'Correccions',
                      const Color(0xFFFFF0E8), const Color(0xFFFF8C42)),
                  const SizedBox(width: 12),
                  _statCard(Icons.check_circle_outline, '2 / 4', 'Pauses',
                      const Color(0xFFE8F5E9), const Color(0xFF43A047)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sensorRow(String name, String value, bool ok) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ok
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: ok ? Colors.green : Colors.red, width: 2),
          ),
          child: Icon(ok ? Icons.check : Icons.warning_amber_rounded,
              size: 14, color: ok ? Colors.green : Colors.red),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(value,
                style: TextStyle(
                    fontSize: 12, color: ok ? Colors.green : Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color bgColor,
      Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── ESTADÍSTIQUES ────────────────────────────────────────────────────────────

class EstadistiquesPage extends StatefulWidget {
  const EstadistiquesPage({super.key});
  @override
  State<EstadistiquesPage> createState() => _EstadistiquesPageState();
}

class _EstadistiquesPageState extends State<EstadistiquesPage> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _weekData = [
    {'day': 'Dl', 'value': 82, 'color': Colors.green},
    {'day': 'Dt', 'value': 74, 'color': const Color(0xFFFF8C42)},
    {'day': 'Dc', 'value': 91, 'color': Colors.green},
    {'day': 'Dj', 'value': 68, 'color': const Color(0xFFFF8C42)},
    {'day': 'Dv', 'value': 78, 'color': const Color(0xFFFF8C42)},
    {'day': 'Ds', 'value': null, 'color': Colors.grey},
    {'day': 'Dg', 'value': null, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Anàlisi de dades',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Text('Estadístiques',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: ['Setmana', 'Mes', 'Any'].asMap().entries.map((e) {
                    final selected = _selectedTab == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4)
                                  ]
                                : [],
                          ),
                          child: Text(e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selected
                                      ? const Color(0xFF4B5EFC)
                                      : Colors.grey)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('% Bona postura',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('Aquesta setmana',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ]),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('79%',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF8C42))),
                              Text('Mitjana',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(children: [
                      Icon(Icons.circle, color: Colors.green, size: 10),
                      SizedBox(width: 4),
                      Text('≥80% Excel·lent',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(width: 12),
                      Icon(Icons.circle, color: Color(0xFFFF8C42), size: 10),
                      SizedBox(width: 4),
                      Text('≥60% Acceptable',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(width: 12),
                      Icon(Icons.circle, color: Colors.red, size: 10),
                      SizedBox(width: 4),
                      Text('<60% Millorable',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _weekData.map((d) {
                        return Column(
                          children: [
                            Text(d['day'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: d['value'] != null
                                    ? (d['color'] as Color).withOpacity(0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: d['value'] != null
                                        ? d['color'] as Color
                                        : Colors.grey.shade300,
                                    width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  d['value'] != null ? '${d['value']}%' : '–',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: d['value'] != null
                                          ? d['color'] as Color
                                          : Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0FE),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.sync,
                                    color: Color(0xFF4B5EFC), size: 16)),
                            const SizedBox(width: 8),
                            const Text('Última sync',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 10),
                          const Text('17:55',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const Text("11 d'abr.",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          const Row(children: [
                            Icon(Icons.circle, color: Colors.green, size: 10),
                            SizedBox(width: 4),
                            Text('Online',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFFFF0E8),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.replay,
                                    color: Color(0xFFFF8C42), size: 16)),
                            const SizedBox(width: 8),
                            const Text('Correccions',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 10),
                          const Text('58',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const Text('aquesta setmana',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          const Text('→ Acceptable',
                              style: TextStyle(
                                  color: Color(0xFFFF8C42),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Correccions per dia',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Menys correccions = millor postura mantinguda',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    _SimpleBarChart(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.trending_up,
                          color: Color(0xFF4B5EFC), size: 18),
                      SizedBox(width: 8),
                      Text("Tendència d'asimetries",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    Text('Desviació postural lateral (en graus)',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.circle, color: Colors.purple, size: 10),
                      SizedBox(width: 4),
                      Text('Esquerra', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 16),
                      Icon(Icons.circle, color: Color(0xFF4B5EFC), size: 10),
                      SizedBox(width: 4),
                      Text('Dreta', style: TextStyle(fontSize: 12)),
                    ]),
                    SizedBox(height: 12),
                    SizedBox(height: 120, child: _SimpleLineChart()),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Asimetria mitjana:',
                            style: TextStyle(color: Colors.grey)),
                        Row(children: [
                          Text('1.5° E',
                              style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Text('-1.2° D',
                              style: TextStyle(
                                  color: Color(0xFF4B5EFC),
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 16),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Descarregar informe',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('Resum complet del mes en PDF',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ])),
                    const Icon(Icons.download_outlined, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [
                          Text('🏆', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Competició',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_add_outlined, size: 16),
                          label: const Text('Convidar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B5EFC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _competitorRow('1', 'MG', 'Maria G.', '🔥 12 dies', 91,
                        Colors.purple, Colors.green, true),
                    _competitorRow('2', 'TU', 'Tu', '🔥 7 dies', 78,
                        const Color(0xFF4B5EFC), const Color(0xFFFF8C42), false,
                        isMe: true),
                    _competitorRow('3', 'PR', 'Pau R.', '🔥 5 dies', 74,
                        Colors.teal, const Color(0xFFFF8C42), false),
                    _competitorRow('4', 'LM', 'Laia M.', '🔥 3 dies', 65,
                        Colors.orange, const Color(0xFFFF8C42), false),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF4B5EFC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Row(
                        children: [
                          Text('👑', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Repte setmanal actiu',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5EFC))),
                                Text(
                                    'Qui aconsegueix el 90% de bona postura primer?',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ])),
                          Icon(Icons.chevron_right, color: Color(0xFF4B5EFC)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _competitorRow(String pos, String initials, String name, String streak,
      int percent, Color avatarColor, Color percentColor, bool isFirst,
      {bool isMe = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEEF1FF) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
              isFirst
                  ? '🥇'
                  : pos == '2'
                      ? '🥈'
                      : pos == '3'
                          ? '🥉'
                          : pos,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFF4B5EFC),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('Tu',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)))
                  ],
                ]),
                Text(streak,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$percent%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: percentColor)),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(percentColor),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data = const [
    {'day': 'Dl', 'value': 13, 'color': Colors.red},
    {'day': 'Dt', 'value': 9, 'color': Color(0xFFFF8C42)},
    {'day': 'Dc', 'value': 5, 'color': Colors.green},
    {'day': 'Dj', 'value': 18, 'color': Colors.red},
    {'day': 'Dv', 'value': 11, 'color': Colors.red},
    {'day': 'Ds', 'value': 0, 'color': Colors.grey},
    {'day': 'Dg', 'value': 0, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final h = (d['value'] as int) * 5.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                  width: 28,
                  height: h.clamp(4.0, 90.0),
                  decoration: BoxDecoration(
                      color: d['color'] as Color,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 4),
              Text(d['day'],
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _LineChartPainter(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [2.0, 1.5, 1.0, 3.5, 2.0, 0.3, 0.4];
    final paint = Paint()
      ..color = const Color(0xFF4B5EFC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = const Color(0xFF4B5EFC)
      ..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i * size.width / (points.length - 1);
      final y = size.height - (points[i] / 4) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    for (int i = 0; i < points.length; i++) {
      final x = i * size.width / (points.length - 1);
      final y = size.height - (points[i] / 4) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── CALIBRACIÓ ───────────────────────────────────────────────────────────────

class CalibracionPage extends StatelessWidget {
  const CalibracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configuració inicial',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Text('Calibració',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF4B5EFC), Color(0xFF7B8FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12))),
                      const SizedBox(width: 16),
                      const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Calibrar sensors',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            Text('Toca per començar la calibració',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ]),
                    ]),
                    const SizedBox(height: 16),
                    const Row(children: [
                      Icon(Icons.circle, color: Color(0xFFFFD700), size: 10),
                      SizedBox(width: 8),
                      Text("Prepara't per seure en postura correcta",
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline, color: Color(0xFF4B5EFC)),
                      SizedBox(width: 8),
                      Text('Com calibrar els sensors',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                        'Segueix aquests passos per obtenir els millors resultats:',
                        style:
                            TextStyle(color: Color(0xFF4B5EFC), fontSize: 13)),
                    const SizedBox(height: 16),
                    ...[
                      "Col·loca el coixí al teu seient habitual",
                      "Seu-te amb l'esquena recta i ben recolzada",
                      "Assegura't que els teus peus toquin el terra",
                      "Prem el botó de calibració quan estiguis còmode",
                      "Mantén aquesta postura durant 3 segons",
                    ].asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF4B5EFC),
                                  shape: BoxShape.circle),
                              child: Center(
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(e.value,
                                    style: const TextStyle(
                                        color: Color(0xFF4B5EFC),
                                        fontSize: 14))),
                          ]),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vídeo tutorial',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                        "Aprèn com col·locar correctament el coixí i calibrar l'aplicació",
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Color(0xFFE8F0FE),
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        child: Icon(Icons.play_circle_outline,
                            size: 48, color: Color(0xFF4B5EFC)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CONFIGURACIÓ ─────────────────────────────────────────────────────────────

class ConfiguracioPage extends StatelessWidget {
  const ConfiguracioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Stack(children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF4B5EFC), Color(0xFF7B8FFF)]),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Center(
                            child: Text('JM',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20))),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Color(0xFF4B5EFC),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 12)),
                      ),
                    ]),
                    const SizedBox(width: 16),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Joan Martínez',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('@joanmartinez',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                          Text('joan.m@exemple.com',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                        ])),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('COMPTE',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(
                    Icons.lock_outline,
                    const Color(0xFFFFE0E0),
                    Colors.red,
                    'Canviar contrasenya',
                    'Actualitza la teva contrasenya'),
                const Divider(height: 1),
                _settingsRow(Icons.language, const Color(0xFFE0F0FF),
                    Colors.blue, 'Idioma', 'Català'),
              ]),
              const SizedBox(height: 24),
              const Text('PREFERÈNCIES',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(
                    Icons.notifications_outlined,
                    const Color(0xFFFFF9E0),
                    Colors.orange,
                    'Notificacions',
                    'Gestiona les alertes que vols rebre'),
                const Divider(height: 1),
                _settingsRow(
                    Icons.track_changes,
                    const Color(0xFFE0FFE8),
                    Colors.green,
                    'Objectius personals',
                    'Defineix les teves metes diàries'),
              ]),
              const SizedBox(height: 24),
              const Center(
                  child: Text('SensorFlow v1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 13))),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(16)),
                child: GestureDetector(
                  onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Tanca la sessió',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(IconData icon, Color bgColor, Color iconColor,
      String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ])),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
