import 'package:flutter/material.dart';

class CalibracionPage extends StatelessWidget {
  const CalibracionPage({super.key});

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
              const Text('Configuració inicial',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const Text('Calibració',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFB5A1E5), Color(0xFF8C82D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 20, offset: Offset(0, 8))
                    ]),
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
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x04000000), blurRadius: 16, offset: Offset(0, 6))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline, color: Color(0xFFB5A1E5)),
                      SizedBox(width: 8),
                      Text('Com calibrar els sensors',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                        'Segueix aquests passos per obtenir els millors resultats:',
                        style:
                            TextStyle(color: Color(0xFF9094A6), fontSize: 13)),
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
                                  color: Color(0xFFB5A1E5),
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
                                        color: Color(0xFF2D3142),
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
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x04000000), blurRadius: 16, offset: Offset(0, 6))
                    ]),
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
                            color: Color(0xFFF2F0F9),
                            borderRadius:
                                BorderRadius.all(Radius.circular(16))),
                        child: Icon(Icons.play_circle_outline,
                            size: 48, color: Color(0xFFB5A1E5)),
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
