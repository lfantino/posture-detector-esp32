import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'estadistiques_page.dart';
import 'calibracion_page.dart';
import 'configuracio_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // Llista de pestanyes. Ha de ser getter o generar-se dins el build 
  // per poder passar funcions de callback cap a la UI.
  List<Widget> get _pages => [
    const DashboardPage(),
    const EstadistiquesPage(),
    CalibracionPage(onFinished: () {
      setState(() {
        _currentIndex = 0;
      });
    }),
    const ConfiguracioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack manté el state de totes les pestanyes actiu.
      // Així, ConfiguracioPage no es destrueix quan canvies de pestanya
      // i els valors carregats de la BD es conserven.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFB5A1E5),
        unselectedItemColor: const Color(0xFFB0B4C4),
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Estadístiques'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_outlined), activeIcon: Icon(Icons.tune), label: 'Calibració'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Configuració'),
        ],
      ),
    );
  }
}
