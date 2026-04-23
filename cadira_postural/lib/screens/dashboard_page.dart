import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../posture_control.dart';
import 'dart:io';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PostureController _controller = PostureController.instance;

  @override
  void initState() {
    super.initState();
    // Connectem a l'escultador de dades
    _controller.addListener(_updateUI);
    // Assegurem que el simulador estigui corrent
    _controller.start();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

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
    final bool hiHaAlerta = !_controller.hiHaAlgu || _controller.bonPostura < 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
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
                            text: 'Bon dia, ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142))),
                        TextSpan(
                            text: '$username ',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB5A1E5))),
                        const TextSpan(
                            text: '👋', style: TextStyle(fontSize: 20)),
                      ])),
                    ],
                  ),
                  _buildNotificationIcon(),
                ],
              ),

              // ── Alerta dinàmica ───────────────────────────────────────────
              if (hiHaAlerta && _controller.hiHaAlgu) ...[
                const SizedBox(height: 20),
                _buildAlertBanner(
                  title: 'Postura incorrecta detectada',
                  subtitle: 'Ajusta la teva posició per evitar lesions.',
                  color: const Color(0xFFF3B3A6),
                  icon: Icons.warning_amber_rounded,
                ),
              ],

              if (!_controller.curvaturaCervicalLumbarOk && _controller.hiHaAlgu) ...[
                const SizedBox(height: 16),
                _buildSimpleAlert('Ves amb compte! Sembla que estàs massa inclinat cap endavant'),
              ],

              if (!_controller.culFrontalOk && _controller.pressioCulDavant > _controller.pressioCulDarrere && _controller.hiHaAlgu) ...[
                const SizedBox(height: 16),
                _buildSimpleAlert('Compte! Sembla que estas seient molt a la vora de la cadira.'),
              ],

              if (!_controller.culLateralOk && _controller.hiHaAlgu) ...[
                const SizedBox(height: 16),
                _buildSimpleAlert('Compte! Sembla que estàs carregant el teu pes a una sola banda.'),
              ],

              if (!_controller.esquenaLateralOk && _controller.hiHaAlgu) ...[
                const SizedBox(height: 16),
                _buildSimpleAlert("Compte! Sembla que no estàs recolzant l'esquena equilibradament"),
              ],

              const SizedBox(height: 20),

              // ── Resum Principal (Score i Temps) ───────────────────────────
              _buildMainScoreCard(),

              const SizedBox(height: 20),

              // ── Bloc de Distribucions (Seient i Respatller) ───────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSeatDistributionCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBackrestDistributionCard()),
                ],
              ),

              const SizedBox(height: 16),

              // ── Bloc d'Ultrasons ──────────────────────────────────────────
              _buildUltrasoundCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Secció de Ginys d'Alta Qualitat ────────────────────────────────────────

  Widget _buildNotificationIcon() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))
          ]),
      child: const Icon(Icons.notifications_outlined, color: Colors.grey),
    );
  }

  Widget _buildAlertBanner({required String title, required String subtitle, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.withRed(150), fontSize: 14)),
                Text(subtitle, style: TextStyle(color: color.withRed(100), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.close, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildMainScoreCard() {
    final double percent = _controller.bonPostura;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 30, offset: Offset(0, 10))
          ]),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 160, height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle de fons
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 20,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent.withOpacity(0.05)),
                  ),
                  // Progressiva
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: percent),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 20,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB5A1E5)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(percent * 100).toInt()}%',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
                      const Text('Bona postura', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildTimeStat('Última sessió', _controller.tempsAssegutFormatat),
              const SizedBox(width: 16),
              _buildTimeStat('Total avui', _controller.tempsAssegutTotalFormatat),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F0F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFB5A1E5), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatDistributionCard() {
    return _buildSensorMapCard(
      title: 'Distribució pressió seient',
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent.withOpacity(0.1), width: 1.5),
          borderRadius: BorderRadius.circular(100), // Forma de cul/seient
          color: Colors.blueAccent.withOpacity(0.02),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sensorPairRow(0, 1),
            _sensorPairRow(2, 3),
            _sensorPairRow(4, 5),
          ],
        ),
      ),
    );
  }

  Widget _buildBackrestDistributionCard() {
    return _buildSensorMapCard(
      title: 'Distribució pressió respatller',
      child: Container(
        height: 180,
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent.withOpacity(0.1), width: 1.5),
          borderRadius: BorderRadius.circular(20), // Forma de respatller
          color: Colors.blueAccent.withOpacity(0.02),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sensorPairRow(6, 7),
            _sensorPairRow(8, 9),
            _sensorPairRow(10, 11),
          ],
        ),
      ),
    );
  }

  Widget _buildUltrasoundCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 20, offset: Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distàncies ultrasons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70, height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ultrasoundPoint(12, 'Cervical'),
                    _ultrasoundPoint(13, 'Toràcic'),
                    _ultrasoundPoint(14, 'Lumbar'),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ultrasoundLabel('Cervical', _controller.usCervical, _controller.cervicalOk),
                  const SizedBox(height: 45),
                  _ultrasoundLabel('Toràcic', _controller.usToracic, _controller.toracicOk),
                  const SizedBox(height: 45),
                  _ultrasoundLabel('Lumbar', _controller.usLumbar, _controller.lumbarOk),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSensorMapCard({required String title, required Widget child}) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          const Spacer(),
          child,
          const Spacer(),
        ],
      ),
    );
  }

  Widget _sensorPairRow(int idx1, int idx2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _sensorPoint(idx1),
        _sensorPoint(idx2),
      ],
    );
  }

  Widget _sensorPoint(int index) {
    final bool isSeatSensor = index >= 0 && index <= 5;
    final bool isBackrestSensor = index >= 6 && index <= 11;

    // Identificació de costats/files per al seient
    final bool isSeatLeftSide = index == 0 || index == 2 || index == 4;
    final bool isSeatFrontRow = index == 4 || index == 5;
    final bool isSeatBackRow = index == 0 || index == 1;

    // Identificació de costats per al respatller
    final bool isBackrestLeftSide = index == 6 || index == 8 || index == 10;

    // Obtenim el valor real (0-100) i l'escalem de 0 a 10 per mostrar-lo
    final double rawVal = _controller.getSensorValue(index);
    int value = 0;
    if (_controller.hiHaAlgu) {
      value = (rawVal / 10).clamp(1, 10).toInt();
    }

    // Lògica per al seient i respatller
    Color color;
    Color textColor;
    double outerSize = 36;
    double innerSize = 26;

    if (isSeatSensor) {
      final bool lateralError = !_controller.culLateralOk && _controller.hiHaAlgu;
      final bool frontalError = !_controller.culFrontalOk && _controller.hiHaAlgu;

      if (lateralError || frontalError) {
        color = const Color(0xFFF3B3A6);
        textColor = Colors.black;

        // MIDA SEIENT
        if (lateralError && frontalError) {
          final bool leftDominant = _controller.pressioCulEsq > _controller.pressioCulDret;
          if ((leftDominant && isSeatLeftSide) || (!leftDominant && !isSeatLeftSide)) {
            outerSize = 48; innerSize = 34;
          }
        } else if (lateralError) {
          final bool leftDominant = _controller.pressioCulEsq > _controller.pressioCulDret;
          if ((leftDominant && isSeatLeftSide) || (!leftDominant && !isSeatLeftSide)) {
            outerSize = 48; innerSize = 34;
          }
        } else if (frontalError) {
          final bool frontDominant = _controller.pressioCulDavant > _controller.pressioCulDarrere;
          if ((frontDominant && isSeatFrontRow) || (!frontDominant && isSeatBackRow)) {
            outerSize = 48; innerSize = 34;
          }
        }

        // COLOR SEIENT (Fosc si hi ha els dos)
        if (lateralError && frontalError) {
          final bool frontDominant = _controller.pressioCulDavant > _controller.pressioCulDarrere;
          if ((frontDominant && isSeatFrontRow) || (!frontDominant && isSeatBackRow)) {
            color = const Color(0xFFD17869);
          }
        }
      } else {
        color = const Color(0xFFA8D5BA);
        textColor = color.withRed(50);
      }
    } else if (isBackrestSensor) {
      final bool lateralError = !_controller.esquenaLateralOk && _controller.hiHaAlgu;

      if (lateralError) {
        color = const Color(0xFFF3B3A6);
        textColor = Colors.black;

        final bool leftDominant = _controller.pressioEsquenaEsq > _controller.pressioEsquenaDret;
        if ((leftDominant && isBackrestLeftSide) || (!leftDominant && !isBackrestLeftSide)) {
          outerSize = 48;
          innerSize = 34;
        }
      } else {
        color = const Color(0xFFA8D5BA);
        textColor = color.withRed(50);
      }
    } else {
      // Altres sensors (ultrasons si es mostressin aquí)
      final bool ok = _controller.isSensorOk(index);
      color = ok ? const Color(0xFFA8D5BA) : const Color(0xFFF3B3A6);
      textColor = color.withRed(50);
    }

    return Container(
      width: outerSize, height: outerSize,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, spreadRadius: 2)]
      ),
      child: Center(
        child: Container(
          width: innerSize, height: innerSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(child: Text('$value', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
      ),
    );
  }

  Widget _ultrasoundPoint(int index, String label) {
    final bool ok = _controller.isSensorOk(index);
    final color = ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2), width: 4)),
      child: Center(
        child: Container(width: 15, height: 15, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }

  Widget _ultrasoundLabel(String label, double val, bool ok) {
    final color = ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142))),
        Text('${val.toInt()} cm', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildSimpleAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.deepOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
