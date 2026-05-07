import 'package:flutter/material.dart';

class EstadistiquesPage extends StatefulWidget {
  const EstadistiquesPage({super.key});
  @override
  State<EstadistiquesPage> createState() => _EstadistiquesPageState();
}

class _EstadistiquesPageState extends State<EstadistiquesPage> {
  // Toggle per al gràfic 1 (0 = Setmana, 1 = Mes)
  int _tempsAssegutTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
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
                      color: Color(0xFF2D3142))),
              const SizedBox(height: 24),

              // 1. Temps assegut (Setmana / Mes)
              _buildTempsAssegutCard(),
              const SizedBox(height: 20),

              // 2. Nota mitjana
              _buildNotaMitjanaCard(),
              const SizedBox(height: 20),

              // 3. Alertes mala postura
              _buildAlertesPosturaCard(),
              const SizedBox(height: 20),

              // 4. Alertes aixecar-se
              _buildAlertesAixecarseCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTempsAssegutCard() {
    final isSetmana = _tempsAssegutTab == 0;
    
    // Dades de simulació per la demo
    final List<String> labelsSetmana = ['Dl\n20/04', 'Dt\n21/04', 'Dc\n22/04', 'Dj\n23/04', 'Dv\n24/04', 'Ds\n25/04', 'Dg\n26/04'];
    final List<double> valuesSetmana = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // hores

    return _buildBaseCard(
      title: 'Temps assegut',
      subtitle: isSetmana ? 'Hores per dia aquesta setmana' : 'Hores de seient per dia aquest mes',
      icon: Icons.timer_outlined,
      iconColor: const Color(0xFFB5A1E5), // Lila
      headerAction: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F0F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton('Setmana', 0),
            _buildTabButton('Mes', 1),
          ],
        ),
      ),
      child: isSetmana 
          ? _buildBarChart(
              labelsSetmana, 
              valuesSetmana, 
              8.0, 
              'h', 
              const Color(0xFFB5A1E5),
              colorBuilder: (val) {
                if (val < 6) return const Color(0xFF2ECC71); // Verd
                if (val <= 8) return const Color(0xFFF39C12); // Taronja
                return const Color(0xFFE74C3C); // Vermell
              }
            )
          : _buildCalendarView(),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _tempsAssegutTab == index;
    return GestureDetector(
      onTap: () => setState(() => _tempsAssegutTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4)] : [],
        ),
        child: Text(text, style: TextStyle(
          fontSize: 12, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? const Color(0xFF2D3142) : Colors.grey
        )),
      ),
    );
  }

  Widget _buildCalendarView() {
    // Dades de simulació per un mes sencer (Abril 2026, 30 dies)
    // El 1 d'abril de 2026 cau en Dimecres
    // Índexs de la setmana: 0=Dl, 1=Dt, 2=Dc, 3=Dj, 4=Dv, 5=Ds, 6=Dg
    const int emptyDaysBefore = 2; // Dl i Dt buits abans de començar el dia 1 (Dc)
    const int totalDays = 30; // Abril té 30 dies
    
    // Generem dades aleatòries per les hores de cada dia
    final List<double?> dailyHours = List.generate(42, (index) {
      if (index < emptyDaysBefore || index >= emptyDaysBefore + totalDays) {
        return null; // Fora del mes
      }
      return 0.0; // sense dades encara
    });

    final List<String> weekDays = ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: Colors.grey), onPressed: () {}),
            const Text('Abril 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
            IconButton(icon: const Icon(Icons.chevron_right, color: Colors.grey), onPressed: () {}),
          ],
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final hours = dailyHours[index];
              if (hours == null) {
                return Container(); // Dia buit
              }
              
              // Lògica de colors per a les hores assegut
              Color cellColor;
              if (hours < 6) {
                cellColor = const Color(0xFF2ECC71); // Verd
              } else if (hours <= 8) {
                cellColor = const Color(0xFFF39C12); // Taronja
              } else {
                cellColor = const Color(0xFFE74C3C); // Vermell
              }
              
              int dayNumber = index - emptyDaysBefore + 1;
              
              return Container(
                decoration: BoxDecoration(
                  color: cellColor.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$dayNumber', style: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        )),
                        Text('${hours.toInt()}h', style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white
                        ))
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotaMitjanaCard() {
    final labels = ['Dl\n20/04', 'Dt\n21/04', 'Dc\n22/04', 'Dj\n23/04', 'Dv\n24/04', 'Ds\n25/04', 'Dg\n26/04'];
    final values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // %
    
    return _buildBaseCard(
      title: 'Nota mitjana de postura',
      subtitle: 'Puntuació mitjana per dia (%)',
      icon: Icons.star_border_rounded,
      iconColor: const Color(0xFF8C82D6), // Lila principal
      child: _buildBarChart(
        labels, 
        values, 
        100.0, 
        '%', 
        const Color(0xFF8C82D6),
        colorBuilder: (val) {
          if (val < 50) return const Color(0xFF800000); // Granate
          if (val <= 80) return const Color(0xFFF39C12); // Taronja
          return const Color(0xFF2ECC71); // Verd
        }
      ),
    );
  }

  Widget _buildAlertesPosturaCard() {
    final labels = ['Dl\n20/04', 'Dt\n21/04', 'Dc\n22/04', 'Dj\n23/04', 'Dv\n24/04', 'Ds\n25/04', 'Dg\n26/04'];
    final values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // Quantitat
    
    return _buildBaseCard(
      title: 'Alertes per mala postura',
      subtitle: 'Avisos rebuts per dia',
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFF800000), // Granat fosc
      child: _buildBarChart(labels, values, 6.0, '', const Color(0xFF800000)),
    );
  }

  Widget _buildAlertesAixecarseCard() {
    final labels = ['Dl\n20/04', 'Dt\n21/04', 'Dc\n22/04', 'Dj\n23/04', 'Dv\n24/04', 'Ds\n25/04', 'Dg\n26/04'];
    final values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // Quantitat
    
    return _buildBaseCard(
      title: "Alertes d'inactivitat",
      subtitle: 'Avisos per aixecar-se i estirar les cames',
      icon: Icons.directions_walk_rounded,
      iconColor: const Color(0xFF7B6CB8), // Lila fred / blavós
      child: _buildBarChart(
        labels, 
        values, 
        20.0, 
        '', 
        const Color(0xFF7B6CB8),
        colorBuilder: (val) {
          if (val < 5) return const Color(0xFF2ECC71); // Verd
          if (val <= 15) return const Color(0xFFF39C12); // Taronja
          return const Color(0xFFE74C3C); // Vermell
        }
      ),
    );
  }

  Widget _buildBaseCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? headerAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 20, offset: Offset(0, 8))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(List<String> labels, List<double> values, double maxValue, String suffix, Color color, {Color Function(double)? colorBuilder}) {
    return SizedBox(
      height: 175,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(labels.length, (index) {
          final val = values[index];
          final heightFactor = maxValue > 0 ? (val / maxValue).clamp(0.0, 1.0) : 0.0;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Etiqueta del valor damunt la barra
              Text('${val == val.toInt() ? val.toInt() : val.toStringAsFixed(1)}$suffix', 
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              // Barra
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 24,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6)
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    width: 24,
                    height: 100 * heightFactor,
                    decoration: BoxDecoration(
                      color: (colorBuilder != null ? colorBuilder(val) : color).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6)
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              // Etiqueta dia/setmana
              Text(labels[index], 
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3, fontWeight: FontWeight.w600)),
            ],
          );
        }),
      ),
    );
  }
}
