import 'package:flutter/material.dart';

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
