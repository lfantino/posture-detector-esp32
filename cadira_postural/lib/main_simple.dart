import 'package:flutter/material.dart';
import 'posture_control.dart';

// Punt d'entrada per aquesta prova simple
void main() {
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Test Sencillo',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const SimpleScreen(),
    );
  }
}

class SimpleScreen extends StatefulWidget {
  const SimpleScreen({super.key});

  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen> {
  // 1. Inicializamos tu "Cerebro"
  final PostureController _controller = PostureController();

  @override
  void initState() {
    super.initState();
    // 2. Encendemos la silla al abrir esta pantalla
    _controller.start();
  }

  @override
  void dispose() {
    // 3. Importante: apagamos la silla al cerrar la app
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Visual Sencillo'),
        backgroundColor: Colors.black45,
      ),
      body: Center(
        // EXPLICACIÓN MAGIA: 
        // ¡ListenableBuilder es el secreto!
        // Le pasamos el "_controller". Flutter se queda escuchando, y 
        // cada vez que el controlador hace un "notifyListeners()",
        // Flutter redibuja SÓLO lo que hay dentro de este builder.
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            
            // Logica visual de color según la "nota" de la postura
            Color postureColor = Colors.green;
            if (_controller.bonPostura < 0.8) postureColor = Colors.orange;
            if (_controller.bonPostura < 0.5) postureColor = Colors.red;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Gráfico circular de postura ---
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: postureColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: postureColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5
                      )
                    ]
                  ),
                  child: Center(
                    child: Text(
                      '${(_controller.bonPostura * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // --- Textos extra para comprobar tu lógica ---
                
                Text(
                  _controller.hiHaAlgu ? '¡Detecto peso! (Alguien sentado)' : 'Silla vacía...',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: _controller.hiHaAlgu ? Colors.white : Colors.grey
                  ),
                ),
                
                const SizedBox(height: 20),

                Text(
                  '⏳ Esta sentada: ${_controller.tempsAssegutFormatat}',
                  style: const TextStyle(fontSize: 18, color: Colors.blueAccent),
                ),
                
                const SizedBox(height: 5),

                Text(
                  '📚 Total hoy: ${_controller.tempsAssegutTotalFormatat}',
                  style: const TextStyle(fontSize: 18, color: Colors.blueAccent),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
