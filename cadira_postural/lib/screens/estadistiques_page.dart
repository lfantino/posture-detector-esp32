import 'package:flutter/material.dart';

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
