import 'package:flutter/material.dart';
import '../services/user_session.dart';
import '../services/bluetooth_service.dart';
import '../posture_control.dart';
import 'bluetooth_page.dart';
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
    BluetoothService.instance.connectionState.addListener(_updateUI);
    // Assegurem que el simulador estigui corrent
    _controller.start();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateUI);
    BluetoothService.instance.connectionState.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  /// Data actual en format llegible en català.
  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'dilluns',
      'dimarts',
      'dimecres',
      'dijous',
      'divendres',
      'dissabte',
      'diumenge'
    ];
    const months = [
      'de gener',
      'de febrer',
      'de març',
      "d'abril",
      'de maig',
      'de juny',
      'de juliol',
      "d'agost",
      'de setembre',
      "d'octubre",
      'de novembre',
      'de desembre'
    ];
    return 'Avui, ${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final username = UserSession().displayName;
    final bool isDisabled = _controller.currentSource == DataSource.bluetooth && 
        BluetoothService.instance.connectionState.value != BtConnectionState.connected;
    final bool hiHaAlerta =
        !isDisabled && (!_controller.hiHaAlgu || _controller.bonPostura < 0.7);

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
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
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

              // ── Indicador d'estat Bluetooth ────────────────────────────
              const SizedBox(height: 12),
              _buildBluetoothStatusBar(),

              // ── Alertes dinàmiques (contenidor fix amb scroll) ────────────
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (hiHaAlerta && _controller.hiHaAlgu)
                        _buildAlertBanner(
                          title: 'Postura incorrecta detectada',
                          subtitle: 'Ajusta la teva posició per evitar lesions.',
                          color: const Color(0xFFF3B3A6),
                          icon: Icons.warning_amber_rounded,
                        ),

                      if (!_controller.curvaturaCervicalLumbarOk &&
                          _controller.hiHaAlgu) ...[
                        const SizedBox(height: 8),
                        _buildSimpleAlert(
                            'Ves amb compte! Sembla que estàs massa inclinat cap endavant'),
                      ],

                      if (!_controller.culFrontalOk &&
                          _controller.pressioCulDavant >
                              _controller.pressioCulDarrere &&
                          _controller.hiHaAlgu) ...[
                        const SizedBox(height: 8),
                        _buildSimpleAlert(
                            'Compte! Sembla que estas seient molt a la vora de la cadira.'),
                      ],

                      if (!_controller.culLateralOk && _controller.hiHaAlgu) ...[
                        const SizedBox(height: 8),
                        _buildSimpleAlert(
                            'Compte! Sembla que estàs carregant el teu pes a una sola banda.'),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Resum Principal (Score i Temps) ───────────────────────────
              _buildMainScoreCard(isDisabled),

              const SizedBox(height: 20),

              // ── Bloc de Distribucions i Ultrasons ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSeatDistributionCard(isDisabled)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUltrasoundCard(isDisabled)),
                ],
              ),

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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))
          ]),
      child: const Icon(Icons.notifications_outlined, color: Colors.grey),
    );
  }

  Widget _buildAlertBanner(
      {required String title,
      required String subtitle,
      required Color color,
      required IconData icon}) {
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
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color.withRed(150),
                        fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: color.withRed(100), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.close, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildMainScoreCard(bool isDisabled) {
    final double percent = isDisabled ? 0.0 : (_controller.hiHaAlgu ? _controller.bonPostura : 0.0);
    final Color circleColor = isDisabled ? Colors.grey.shade400 : const Color(0xFFB5A1E5);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 30, offset: Offset(0, 10))
          ]),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  OverflowBox(
                    maxWidth: 195,
                    maxHeight: 195,
                    child: SizedBox(
                      width: 195,
                      height: 195,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cercle de fons
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent.withOpacity(0.05)),
                          ),
                          // Progressiva
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: percent),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                CircularProgressIndicator(
                              value: value,
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(circleColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(percent * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDisabled ? Colors.grey : const Color(0xFF4A4A4A))),
                      Text(isDisabled ? 'Bluetooth no connectat' : 'Bona postura',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimeStat('Última sessió', _controller.tempsAssegutFormatat),
              const SizedBox(width: 16),
              _buildTimeStat(
                  'Total avui', _controller.tempsAssegutTotalFormatat),
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
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFB5A1E5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142))),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatDistributionCard(bool isDisabled) {
    return _buildSensorMapCard(
      title: 'Distribució pressió seient',
      isDisabled: isDisabled,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border:
              Border.all(color: isDisabled ? Colors.grey.shade300 : Colors.blueAccent.withOpacity(0.1), width: 1.5),
          borderRadius: BorderRadius.circular(100), // Forma de cul/seient
          color: isDisabled ? Colors.grey.withOpacity(0.05) : Colors.blueAccent.withOpacity(0.02),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sensorPairRow(0, 1, isDisabled),
            _sensorPairRow(2, 3, isDisabled),
            _sensorPairRow(4, 5, isDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildUltrasoundCard(bool isDisabled) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x04000000), blurRadius: 20, offset: Offset(0, 10))
          ]),
      child: Column(
        children: [
          const Text('Distàncies ultrasons',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
          if (isDisabled)
            const Text('Bluetooth no connectat', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ultrasoundPoint(6, 'Cervical', isDisabled),
                    _ultrasoundPoint(7, 'Toràcic', isDisabled),
                    _ultrasoundPoint(8, 'Lumbar', isDisabled),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ultrasoundLabel('Cervical', _controller.usCervical,
                        _controller.cervicalOk, isDisabled),
                    const SizedBox(height: 20),
                    _ultrasoundLabel('Toràcic', _controller.usToracic,
                        _controller.toracicOk, isDisabled),
                    const SizedBox(height: 20),
                    _ultrasoundLabel(
                        'Lumbar', _controller.usLumbar, _controller.lumbarOk, isDisabled),
                  ],
                ),
              )
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSensorMapCard({required String title, required bool isDisabled, required Widget child}) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x04000000), blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center),
          if (isDisabled)
            const Text('Bluetooth no connectat', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const Spacer(),
          child,
          const Spacer(),
        ],
      ),
    );
  }

  Widget _sensorPairRow(int idx1, int idx2, bool isDisabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _sensorPoint(idx1, isDisabled),
        _sensorPoint(idx2, isDisabled),
      ],
    );
  }

  Widget _sensorPoint(int index, bool isDisabled) {
    final bool isSeatSensor = index >= 0 && index <= 5;

    // Identificació de costats/files per al seient
    final bool isSeatLeftSide = index == 0 || index == 2 || index == 4;
    final bool isSeatFrontRow = index == 4 || index == 5;
    final bool isSeatBackRow = index == 0 || index == 1;

    // Obtenim el valor real (0-100) i ho mostrem directament perquè es vegi el canvi
    final double rawVal = _controller.getSensorValue(index);
    int value = 0;
    if (!isDisabled && _controller.hiHaAlgu) {
      value = rawVal.toInt(); // De 0 a 100
    }

    // Lògica per al seient
    Color color;
    Color textColor;
    double outerSize = 36;
    double innerSize = 26;

    if (isDisabled) {
      color = Colors.grey.shade400;
      textColor = Colors.grey.shade700;
    } else if (isSeatSensor) {
      final bool lateralError =
          !_controller.culLateralOk && _controller.hiHaAlgu;
      final bool frontalError =
          !_controller.culFrontalOk && _controller.hiHaAlgu;

      if (lateralError || frontalError) {
        color = const Color(0xFFF3B3A6);
        textColor = Colors.black;

        // MIDA SEIENT
        if (lateralError && frontalError) {
          final bool leftDominant =
              _controller.pressioCulEsq > _controller.pressioCulDret;
          if ((leftDominant && isSeatLeftSide) ||
              (!leftDominant && !isSeatLeftSide)) {
            outerSize = 48;
            innerSize = 34;
          }
        } else if (lateralError) {
          final bool leftDominant =
              _controller.pressioCulEsq > _controller.pressioCulDret;
          if ((leftDominant && isSeatLeftSide) ||
              (!leftDominant && !isSeatLeftSide)) {
            outerSize = 48;
            innerSize = 34;
          }
        } else if (frontalError) {
          final bool frontDominant =
              _controller.pressioCulDavant > _controller.pressioCulDarrere;
          if ((frontDominant && isSeatFrontRow) ||
              (!frontDominant && isSeatBackRow)) {
            outerSize = 48;
            innerSize = 34;
          }
        }

        // COLOR SEIENT (Fosc si hi ha els dos)
        if (lateralError && frontalError) {
          final bool frontDominant =
              _controller.pressioCulDavant > _controller.pressioCulDarrere;
          if ((frontDominant && isSeatFrontRow) ||
              (!frontDominant && isSeatBackRow)) {
            color = const Color(0xFFD17869);
          }
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
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1), blurRadius: 8, spreadRadius: 2)
          ]),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
              child: Text('$value',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ),
      ),
    );
  }

  Widget _ultrasoundPoint(int index, String label, bool isDisabled) {
    final bool ok = !isDisabled && _controller.isSensorOk(index);
    final color = isDisabled ? Colors.grey.shade400 : (ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C));
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2), width: 4)),
      child: Center(
        child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }

  Widget _ultrasoundLabel(String label, double val, bool ok, bool isDisabled) {
    final color = isDisabled ? Colors.grey : (ok ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDisabled ? Colors.grey : const Color(0xFF2D3142))),
        Text(isDisabled ? '0 cm' : '${val.toInt()} cm',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildBluetoothStatusBar() {
    return ValueListenableBuilder<BtConnectionState>(
      valueListenable: BluetoothService.instance.connectionState,
      builder: (context, state, _) {
        Color bgColor;
        Color textColor;
        IconData icon;
        String label;

        switch (state) {
          case BtConnectionState.connected:
            bgColor = const Color(0xFFE8F5E9);
            textColor = const Color(0xFF2E7D32);
            icon = Icons.bluetooth_connected;
            label = 'Connectat a Cadira Postural';
          case BtConnectionState.connecting:
            bgColor = const Color(0xFFFFF8E1);
            textColor = const Color(0xFFF57F17);
            icon = Icons.sync;
            label = 'Connectant...';
          case BtConnectionState.scanning:
            bgColor = const Color(0xFFE3F2FD);
            textColor = const Color(0xFF1565C0);
            icon = Icons.bluetooth_searching;
            label = 'Escanejant...';
          case BtConnectionState.error:
            bgColor = const Color(0xFFFFEBEE);
            textColor = const Color(0xFFC62828);
            icon = Icons.bluetooth_disabled;
            label = 'Error de connexió';
          case BtConnectionState.disconnected:
            bgColor = const Color(0xFFF5F5F5);
            textColor = const Color(0xFF757575);
            icon = Icons.bluetooth_disabled;
            label = _controller.currentSource == DataSource.simulator
                ? 'Mode simulador actiu'
                : 'Toca per connectar';
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BluetoothPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
                Icon(Icons.chevron_right, color: textColor.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        );
      },
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
              style: const TextStyle(
                  color: Colors.deepOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
