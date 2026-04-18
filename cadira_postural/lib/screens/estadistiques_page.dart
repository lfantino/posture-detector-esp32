import 'package:flutter/material.dart';
import '../services/user_session.dart';

class EstadistiquesPage extends StatefulWidget {
  const EstadistiquesPage({super.key});
  @override
  State<EstadistiquesPage> createState() => _EstadistiquesPageState();
}

class _EstadistiquesPageState extends State<EstadistiquesPage> {
  int _selectedTab = 0;

  // Tots els valors a null fins que el dispositiu enviï dades reals
  final List<Map<String, dynamic>> _weekData = const [
    {'day': 'Dl', 'value': null},
    {'day': 'Dt', 'value': null},
    {'day': 'Dc', 'value': null},
    {'day': 'Dj', 'value': null},
    {'day': 'Dv', 'value': null},
    {'day': 'Ds', 'value': null},
    {'day': 'Dg', 'value': null},
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
              // ── Títol ─────────────────────────────────────────────────────
              const Text('Anàlisi de dades',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Text('Estadístiques',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
              const SizedBox(height: 20),

              // ── Selector setmana / mes / any ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: ['Setmana', 'Mes', 'Any']
                      .asMap()
                      .entries
                      .map((e) {
                    final selected = _selectedTab == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTab = e.key),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
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

              // ── % Bona postura per dia ────────────────────────────────────
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
                              Text('--',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
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
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(width: 12),
                      Icon(Icons.circle,
                          color: Color(0xFFFF8C42), size: 10),
                      SizedBox(width: 4),
                      Text('≥60% Acceptable',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(width: 12),
                      Icon(Icons.circle, color: Colors.red, size: 10),
                      SizedBox(width: 4),
                      Text('<60% Millorable',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 16),
                    // Dies de la setmana: tots "--" fins a tenir dades
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
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.5),
                              ),
                              child: const Center(
                                child: Text('–',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
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

              // ── Última sync + Correccions ─────────────────────────────────
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
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 10),
                          const Text('--:--',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const Text('Cap sincronització',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          const Row(children: [
                            Icon(Icons.circle,
                                color: Colors.grey, size: 10),
                            SizedBox(width: 4),
                            Text('Desconnectat',
                                style: TextStyle(
                                    color: Colors.grey,
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
                                    color: Color(0xFFFF8C42),
                                    size: 16)),
                            const SizedBox(width: 8),
                            const Text('Correccions',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 10),
                          const Text('0',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const Text('aquesta setmana',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          const Text('Sense dades',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Correccions per dia (bar chart buit) ──────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Correccions per dia',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                        'Menys correccions = millor postura mantinguda',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    SizedBox(height: 16),
                    _EmptyBarChart(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Tendència d'asimetries (placeholder) ──────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.trending_up,
                          color: Color(0xFF4B5EFC), size: 18),
                      SizedBox(width: 8),
                      Text("Tendència d'asimetries",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const Text('Desviació postural lateral (en graus)',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Sense dades disponibles',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                    const Divider(),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Asimetria mitjana:',
                            style: TextStyle(color: Colors.grey)),
                        Row(children: [
                          Text('-- E',
                              style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Text('-- D',
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

              // ── Descarregar informe ──────────────────────────────────────
              Opacity(
                opacity: 0.5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2ECC71),
                            Color(0xFF27AE60)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
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
                            Text(
                                'Disponible quan hi hagi dades registrades',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                          ])),
                      const Icon(Icons.download_outlined,
                          color: Colors.white70),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Competició (pròximament) ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Text('🏆', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Competició',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline,
                              color: Colors.grey, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${UserSession().displayName}!',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1D2E)),
                                ),
                                const Text(
                                  'La funció de competició amb amics arriba aviat.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
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
}

// ── Widget: Bar chart buit ────────────────────────────────────────────────────

class _EmptyBarChart extends StatelessWidget {
  const _EmptyBarChart();

  static const List<String> _days = [
    'Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _days.map((day) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                      width: 28,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 4),
                  Text(day,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              );
            }).toList(),
          ),
          const Text('Sense dades registrades',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
