import 'package:flutter/material.dart';
import '../services/user_session.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // L'alerta s'activarà quan el dispositiu enviï dades reals (no hardcodeada)
  bool _showAlert = false;

  /// Data actual en format llegible en català.
  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'dilluns', 'dimarts', 'dimecres', 'dijous',
      'divendres', 'dissabte', 'diumenge'
    ];
    const months = [
      'de gener', 'de febrer', 'de març', "d'abril",
      'de maig', 'de juny', 'de juliol', "d'agost",
      'de setembre', "d'octubre", 'de novembre', 'de desembre'
    ];
    return 'Avui, ${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final username = UserSession().displayName;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Capçalera ─────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getFormattedDate(),
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: 'Benvingut de nou, ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1D2E))),
                        TextSpan(
                            text: '$username ',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5EFC))),
                        const TextSpan(
                            text: '👋', style: TextStyle(fontSize: 20)),
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
                    ],
                  ),
                ],
              ),

              // ── Alerta (només amb dades reals) ────────────────────────────
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
                            Text('Porta molt de temps assegut!',
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

              // ── Postura actual ────────────────────────────────────────────
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
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Sense connexió',
                              style: TextStyle(
                                  color: Colors.grey,
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
                              // null = sense dades (color gris, icona neutra)
                              _sensorRow('Cervical', '-- °', null),
                              const SizedBox(height: 16),
                              _sensorRow('Toràcic',  '-- °', null),
                              const SizedBox(height: 16),
                              _sensorRow('Lumbar',   '-- °', null),
                              const SizedBox(height: 12),
                              const Row(children: [
                                Icon(Icons.circle, color: Colors.green, size: 10),
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
                                        value: 0.0,
                                        strokeWidth: 10,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.grey)),
                                    const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('--',
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey)),
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
                              const Text('--',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Banner: connecta el dispositiu ────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF4B5EFC).withValues(alpha: 0.25))),
                child: const Row(
                  children: [
                    Icon(Icons.bluetooth_searching,
                        color: Color(0xFF4B5EFC), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connecta la cadira',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5EFC),
                                  fontSize: 14)),
                          SizedBox(height: 2),
                          Text(
                              'Activa el Bluetooth per rebre dades en temps real.',
                              style: TextStyle(
                                  color: Color(0xFF4B5EFC), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Targetes de resum ─────────────────────────────────────────
              Row(
                children: [
                  _statCard(Icons.access_time, '--', 'Temps actiu',
                      const Color(0xFFE8F0FE), const Color(0xFF4B5EFC)),
                  const SizedBox(width: 12),
                  _statCard(Icons.trending_up, '0', 'Correccions',
                      const Color(0xFFFFF0E8), const Color(0xFFFF8C42)),
                  const SizedBox(width: 12),
                  _statCard(Icons.check_circle_outline, '0', 'Pauses',
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

  // ── Widgets helpers ────────────────────────────────────────────────────────

  /// [ok] = true → verd, false → vermell, null → gris (sense dades).
  Widget _sensorRow(String name, String value, bool? ok) {
    final color = ok == null
        ? Colors.grey
        : (ok ? Colors.green : Colors.red);
    final icon = ok == null
        ? Icons.remove
        : (ok ? Icons.check : Icons.warning_amber_rounded);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text(value, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label,
      Color bgColor, Color iconColor) {
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
              decoration:
                  BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
