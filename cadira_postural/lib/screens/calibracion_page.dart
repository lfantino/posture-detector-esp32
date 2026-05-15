import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../posture_control.dart';
import '../database/database_helper.dart';
import '../services/user_session.dart';

class CalibracionPage extends StatefulWidget {
  final VoidCallback? onFinished;

  const CalibracionPage({super.key, this.onFinished});

  @override
  State<CalibracionPage> createState() => _CalibracionPageState();
}

class _CalibracionPageState extends State<CalibracionPage> {
  int _currentStep = 0; // 0: Intro, 1 a 6: Passos, 7: Summary
  bool _isRecording = false; // Flag per a l'efecte visual de 3 segons

  // Constants / Margins
  final double marginA = 5.0; // cm
  final double marginB = 5.0; // cm
  final double marginC = 250.0; // raw FSR
  final double marginD = 250.0; // raw FSR

  // State
  double? _diffEsq;
  double? _diffDret;
  double? _refCervical;
  double? _refToracic;
  double? _refLumbar;

  // Final calculated thresholds

  double? kMaxDistanciaCervical;
  double? kMaxDistanciaToracic;
  double? kMaxDistanciaLumbar;
  double? kMaxDiferenciaCervicalLumbar;
  double? kMaxDiferenciaFrontal;
  double? kMaxDiferenciaLateralCul;

  void _nextStep() {
    setState(() {
      if (_currentStep < 7) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  void _comencarCalibracio() {
    final pc = PostureController.instance;
    if (pc.currentSource == DataSource.bluetooth && !pc.bluetoothService.isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.red),
              SizedBox(width: 8),
              Text('Bluetooth desconnectat', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: const Text('Si us plau, connecta la cadira via Bluetooth abans de calibrar, o canvia la font de dades a Simulador a la pestanya de Configuració.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entès', style: TextStyle(color: Color(0xFFB5A1E5))),
            )
          ],
        ),
      );
      return;
    }
    _nextStep();
  }

  // PAS 1: Postura de referència (esquena recta i pegada)
  void _gravarPaso1() async {
    if (_isRecording) return;
    try {
      final raw = PostureController.instance.rawValues;
      setState(() {
        _refCervical = raw[6];
        _refToracic = raw[7];
        _refLumbar = raw[8];
        _isRecording = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _nextStep();
    } catch (e) {} finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  // PAS 2: Límit frontal (davant/darrere del coixí)
  void _gravarPaso2() async {
    if (_isRecording) return;
    try {
      final raw = PostureController.instance.rawValues;
      double davant = (raw[4] + raw[5]) / 2;
      double darrere = (raw[0] + raw[1]) / 2;
      setState(() {
        kMaxDiferenciaFrontal = (davant - darrere).abs() * 1.10;
        _isRecording = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _nextStep();
    } catch (e) {} finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  // PAS 3: Pierna Izq sobre Der (peso a la derecha)
  void _gravarPaso3() async {
    if (_isRecording) return;
    try {
      final raw = PostureController.instance.rawValues;
      double mitjaEsq = (raw[0] + raw[2] + raw[4]) / 3;
      double mitjaDret = (raw[1] + raw[3] + raw[5]) / 3;
      setState(() {
        _diffDret = (mitjaEsq - mitjaDret).abs();
        _isRecording = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _nextStep();
    } catch (e) {} finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  // PAS 4: Límit lateral (pes a l'esquerra)
  void _gravarPaso4() async {
    if (_isRecording) return;
    try {
      final raw = PostureController.instance.rawValues;
      double mitjaEsq = (raw[0] + raw[2] + raw[4]) / 3;
      double mitjaDret = (raw[1] + raw[3] + raw[5]) / 3;
      setState(() {
        _diffEsq = (mitjaEsq - mitjaDret).abs();
        if (_diffEsq != null && _diffDret != null) {
          kMaxDiferenciaLateralCul = (_diffEsq! > _diffDret! ? _diffEsq! : _diffDret!) * 1.10;
        }
        _isRecording = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _nextStep();
    } catch (e) {} finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  // PAS 5: Límit de distància al respatller (dret però allunyat)
  void _gravarPaso5() async {
    if (_isRecording) return;
    try {
      final raw = PostureController.instance.rawValues;
      setState(() {
        kMaxDistanciaCervical = raw[6] * 1.10;
        kMaxDistanciaToracic = raw[7] * 1.10;
        kMaxDistanciaLumbar = raw[8] * 1.10;
        _isRecording = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _nextStep();
    } catch (e) {} finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  // PAS 6: Límit de curvatura de la columna (inclinat cap endavant)
  void _gravarPaso6() async {
    if (_isRecording) return;
    try {
      final raw = PostureController.instance.rawValues;
      setState(() {
        kMaxDiferenciaCervicalLumbar = (raw[6] - raw[8]).abs() * 1.10;
        _isRecording = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _nextStep();
    } catch (e) {} finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _finalitzarIGuardar() async {
    PostureController.instance.loadThresholds(
      latCul: kMaxDiferenciaLateralCul,
      frontCul: kMaxDiferenciaFrontal,
      distCerv: kMaxDistanciaCervical,
      distTor: kMaxDistanciaToracic,
      distLumb: kMaxDistanciaLumbar,
      diffCervLumb: kMaxDiferenciaCervicalLumbar,
    );

    final userSession = UserSession();
    if (userSession.userId != null) {
      await DatabaseHelper().desarCalibracio(
        usuariId: userSession.userId!,
        latCul: kMaxDiferenciaLateralCul ?? 0.0,
        frontCul: kMaxDiferenciaFrontal ?? 0.0,
        distCerv: kMaxDistanciaCervical ?? 0.0,
        distTor: kMaxDistanciaToracic ?? 0.0,
        distLumb: kMaxDistanciaLumbar ?? 0.0,
        diffCervLumb: kMaxDiferenciaCervicalLumbar ?? 0.0,
      );
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calibració completada i guardada!')));
    
    if (widget.onFinished != null) {
      widget.onFinished!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuració inicial', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Text('Calibració', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 8,
                    backgroundColor: Colors.white,
                    color: const Color(0xFFB5A1E5),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildIntroStep();
      case 1:
        return _buildStepCard(
          title: "Pas 1: Postura de referència",
          description: "Seu amb l'esquena totalment recta i enganxada al respatller. Aquesta és la teva postura ideal de referència.",
          videoAsset: 'assets/videos/pas1.mp4',
          actionButton: _buildActionButton(_gravarPaso1),
        );
      case 2:
        return _buildStepCard(
          title: "Pas 2: Límit frontal (davant/darrere)",
          description: "Mou el teu cos cap al front, asseient-te només a la vora del coixí. Definirem el desequilibri davant/darrere màxim.",
          videoAsset: 'assets/videos/pas2.mp4',
          actionButton: _buildActionButton(_gravarPaso2),
        );
      case 3:
        return _buildStepCard(
          title: "Pas 3: Referència lateral (pes a la dreta)",
          description: "Posa la cama esquerra sobre la dreta i desplaça tot el pes cap al costat dret.",
          videoAsset: 'assets/videos/pas3.mp4',
          actionButton: _buildActionButton(_gravarPaso3),
        );
      case 4:
        return _buildStepCard(
          title: "Pas 4: Límit lateral (esquerra/dreta)",
          description: "Posa la cama dreta sobre l'esquerra i desplaça tot el pes cap al costat esquerre. Definirem el desequilibri lateral màxim.",
          videoAsset: 'assets/videos/pas4.mp4',
          actionButton: _buildActionButton(_gravarPaso4),
        );
      case 5:
        return _buildStepCard(
          title: "Pas 5: Límit de distància al respatller",
          description: "Seu recte però separa l'esquena del respatller fins a la posició més allunyada que creus acceptable. Definirem la distància màxima tolerable.",
          videoAsset: 'assets/videos/pas5.mp4',
          actionButton: _buildActionButton(_gravarPaso5),
        );
      case 6:
        return _buildStepCard(
          title: "Pas 6: Límit de curvatura de la columna",
          description: "Inclina't cap endavant amb l'esquena corbada fins al límit. Definirem la curvatura màxima de la columna tolerable.",
          videoAsset: 'assets/videos/pas6.mp4',
          actionButton: _buildActionButton(_gravarPaso6),
        );
      case 7:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }


  Widget _buildIntroStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFB5A1E5), Color(0xFF8C82D6)]),
              borderRadius: BorderRadius.circular(24)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.sensors, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calibrar sensors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Adapta la cadira al teu cos', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                ),
              ]),
              SizedBox(height: 16),
              Text("Et guiarem pas a pas amb 6 vídeos curts. Segueix les instruccions exactament.",
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: _comencarCalibracio,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3142),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Començar Calibració', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildStepCard({required String title, required String description, required String videoAsset, required Widget actionButton}) {
    return Container(
      key: ValueKey(_currentStep),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF9094A6))),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: VideoPlayerWidget(videoAsset: videoAsset),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: actionButton),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _isRecording ? null : _prevStep, 
              child: const Text('Enrere', style: TextStyle(color: Colors.grey))
            )
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(VoidCallback onPressed) {
    if (_isRecording) {
      return ElevatedButton(
        onPressed: null,
        style: _btnStyle(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Gravant...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: _btnStyle(),
      child: const Text('Gravar i Continuar'),
    );
  }

  Widget _buildSummaryStep() {
    return Container(
      key: const ValueKey(7),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 64)),
          const SizedBox(height: 16),
          const Center(child: Text("Calibració Completada", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),
          const Text("Nous llindars calculats:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSummaryRow("Dist. Còmoda Cervical", kMaxDistanciaCervical),
          _buildSummaryRow("Dist. Còmoda Toràcica", kMaxDistanciaToracic),
          _buildSummaryRow("Dist. Còmoda Lumbar", kMaxDistanciaLumbar),
          _buildSummaryRow("Dif. Inclinació (Cerv/Lumb)", kMaxDiferenciaCervicalLumbar),
          _buildSummaryRow("Dif. Frontal", kMaxDiferenciaFrontal),
          _buildSummaryRow("Dif. Lateral", kMaxDiferenciaLateralCul),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _finalitzarIGuardar, style: _btnStyle(), child: const Text('Guardar i Finalitzar')),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value != null ? value.toStringAsFixed(1) : '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFB5A1E5),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// Widget auxiliar per carregar i reproduir els vídeos
class VideoPlayerWidget extends StatefulWidget {
  final String videoAsset;
  const VideoPlayerWidget({super.key, required this.videoAsset});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _controller.setLooping(true);
            _controller.setVolume(0.0);
            _controller.play();
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _errorMsg = error.toString();
          });
        }
        print("Error carregant vídeo ${widget.videoAsset}: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Container(
        color: const Color(0xFFF2F0F9),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text('Error de vídeo:\n$_errorMsg', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 10)),
            ],
          ),
        ),
      );
    } else if (_initialized) {
      return VideoPlayer(_controller);
    } else {
      return Container(
        color: const Color(0xFFF2F0F9),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB5A1E5)),
        ),
      );
    }
  }
}
