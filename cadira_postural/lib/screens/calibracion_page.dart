import 'package:flutter/material.dart';
import '../posture_control.dart';

class CalibracionPage extends StatefulWidget {
  final VoidCallback? onFinished;

  const CalibracionPage({super.key, this.onFinished});

  @override
  State<CalibracionPage> createState() => _CalibracionPageState();
}

class _CalibracionPageState extends State<CalibracionPage> {
  int _currentStep = 0; // 0: Intro, 1: 1.1, 2: 1.2, 3: 2, 4: 3, 5: End

  // Constants / Margins
  final double marginA = 5.0; // cm
  final double marginB = 5.0; // cm
  final double marginC = 250.0; // raw FSR
  final double marginD = 250.0; // raw FSR

  // State for Calibration 3 (Lateral)
  bool _lateralEsqGravat = false;
  double? _diffEsq;
  double? _diffDret;

  // Final calculated thresholds
  double? kMaxDistanciaCervical;
  double? kMaxDistanciaToracic;
  double? kMaxDistanciaLumbar;
  double? kMaxDiferenciaCervicalLumbar;
  double? kMaxDiferenciaFrontal;
  double? kMaxDiferenciaLateralCul;

  void _nextStep() {
    setState(() {
      if (_currentStep < 5) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  void _gravarUltrasonsRecte() {
    try {
      final pc = PostureController.instance;
      final raw = pc.rawValues;
      // 1.1 Ultrasons de l'esquena (Recte)
      // index 6: Cervical, 7: Toràcic, 8: Lumbar
      setState(() {
        kMaxDistanciaCervical = raw[6] + marginA;
        kMaxDistanciaToracic = raw[7] + marginA;
        kMaxDistanciaLumbar = raw[8] + marginA;
      });
      _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _gravarUltrasonsInclinat() {
    try {
      final pc = PostureController.instance;
      final raw = pc.rawValues;
      // 1.2 Ultrasons esquena (Inclinat)
      setState(() {
        double diff = (raw[6] - raw[8]).abs();
        kMaxDiferenciaCervicalLumbar = diff + marginB;
      });
      _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _gravarFrontalCoixi() {
    try {
      final pc = PostureController.instance;
      final raw = pc.rawValues;
      // 2. Frontal coixí inferior (Punta)
      // Davant = index 4,5; Darrere = index 0,1
      double davant = (raw[4] + raw[5]) / 2;
      double darrere = (raw[0] + raw[1]) / 2;
      setState(() {
        kMaxDiferenciaFrontal = (davant - darrere).abs() + marginC;
      });
      _nextStep();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _gravarLateral(bool esquerra) {
    try {
      final pc = PostureController.instance;
      final raw = pc.rawValues;
      
      // Esquena = 0, Mig = 2, Davant = 4 (costat esquerre)
      // Esquena = 1, Mig = 3, Davant = 5 (costat dret)
      double mitjaEsq = (raw[0] + raw[2] + raw[4]) / 3;
      double mitjaDret = (raw[1] + raw[3] + raw[5]) / 3;
      
      setState(() {
        if (esquerra) {
          _diffEsq = (mitjaEsq - mitjaDret).abs();
          _lateralEsqGravat = true;
        } else {
          _diffDret = (mitjaEsq - mitjaDret).abs();
          
          // Final calc for step 3
          if (_diffEsq != null && _diffDret != null) {
            double avgDiff = (_diffEsq! + _diffDret!) / 2;
            kMaxDiferenciaLateralCul = avgDiff + marginD;
            _nextStep();
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _finalitzarIGuardar() {
    // Injectem al PostureController
    PostureController.instance.loadThresholds(
      latCul: kMaxDiferenciaLateralCul,
      frontCul: kMaxDiferenciaFrontal,
      distCerv: kMaxDistanciaCervical,
      distTor: kMaxDistanciaToracic,
      distLumb: kMaxDistanciaLumbar,
      diffCervLumb: kMaxDiferenciaCervicalLumbar,
    );

    // TODO: Desament a DatabaseHelper un cop la taula estigui preparada
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibració completada i guardada!')),
    );
    
    // Tornar al pas inicial per si l'usuari hi torna més tard
    setState(() {
      _currentStep = 0;
      _lateralEsqGravat = false;
      _diffEsq = null;
      _diffDret = null;
    });

    // Navegar al Dashboard si tenim la funció
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  const SizedBox(height: 10),
                  // Progress Bar
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 6,
                    backgroundColor: Colors.white,
                    color: const Color(0xFFB5A1E5),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Content
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
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildStepCard(
          title: "1.1 Ultrasons de l'esquena",
          description: "Seu amb l'esquena recta i ben recolzada contra el respatller. Aquest pas mesurarà la distància òptima de la teva columna.",
          videoPlaceholder: true,
          actionButton: ElevatedButton(
            onPressed: _gravarUltrasonsRecte,
            style: _btnStyle(),
            child: const Text('Gravar Posició Recta'),
          ),
        );
      case 2:
        return _buildStepCard(
          title: "1.2 Inclinació de l'esquena",
          description: "Inclina't lleugerament cap endavant fins al punt màxim on consideres que encara estàs ben assegut.",
          videoPlaceholder: true,
          actionButton: ElevatedButton(
            onPressed: _gravarUltrasonsInclinat,
            style: _btnStyle(),
            child: const Text('Gravar Posició Inclinada'),
          ),
        );
      case 3:
        return _buildStepCard(
          title: "2. Frontal del coixí inferior",
          description: "Seu a la punta del coixí, molt endavant, amb el cul només recolzat a l'extrem del seient.",
          videoPlaceholder: true,
          actionButton: ElevatedButton(
            onPressed: _gravarFrontalCoixi,
            style: _btnStyle(),
            child: const Text('Gravar Posició Punta'),
          ),
        );
      case 4:
        return _buildStepCard(
          title: "3. Lateral del coixí inferior",
          description: _lateralEsqGravat 
              ? "Ara recolza tot el teu pes cap a l'altre lateral (Dret)."
              : "Seu recolzant tot el teu pes cap a un lateral (Esquerre).",
          videoPlaceholder: true,
          actionButton: ElevatedButton(
            onPressed: () => _gravarLateral(!_lateralEsqGravat),
            style: _btnStyle(),
            child: Text(_lateralEsqGravat ? 'Gravar Costat Dret' : 'Gravar Costat Esquerre'),
          ),
        );
      case 5:
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
              gradient: const LinearGradient(
                  colors: [Color(0xFFB5A1E5), Color(0xFF8C82D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 20,
                    offset: Offset(0, 8))
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
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.sensors, color: Colors.white)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calibrar sensors',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('Adapta la cadira al teu cos',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                ),
              ]),
              const SizedBox(height: 16),
              const Row(children: [
                Icon(Icons.circle, color: Color(0xFFFFD700), size: 10),
                SizedBox(width: 8),
                Expanded(child: Text("Et guiarem pas a pas. Són només 4 passos.",
                    style: TextStyle(color: Colors.white, fontSize: 13))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3142),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Començar Calibració', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildStepCard({
    required String title,
    required String description,
    required bool videoPlaceholder,
    required Widget actionButton,
  }) {
    return Container(
      key: ValueKey(_currentStep),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 12),
          Text(description,
              style: const TextStyle(fontSize: 15, color: Color(0xFF9094A6))),
          const SizedBox(height: 24),
          if (videoPlaceholder)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F0F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E0F2), width: 1),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill,
                        size: 64, color: Color(0xFFB5A1E5)),
                    SizedBox(height: 8),
                    Text('Vídeo il·lustratiu (Pendent)', style: TextStyle(color: Colors.grey, fontSize: 12))
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: actionButton,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _prevStep,
              child: const Text('Enrere', style: TextStyle(color: Colors.grey)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Container(
      key: const ValueKey(5),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.check_circle, color: Colors.green, size: 64),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text("Calibració Completada",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142))),
          ),
          const SizedBox(height: 24),
          const Text("Nous llindars calculats:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSummaryRow("Dist. Cervical", kMaxDistanciaCervical),
          _buildSummaryRow("Dist. Toràcic", kMaxDistanciaToracic),
          _buildSummaryRow("Dist. Lumbar", kMaxDistanciaLumbar),
          _buildSummaryRow("Dif. Cervical/Lumbar", kMaxDiferenciaCervicalLumbar),
          _buildSummaryRow("Dif. Frontal Cul", kMaxDiferenciaFrontal),
          _buildSummaryRow("Dif. Lateral Cul", kMaxDiferenciaLateralCul),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finalitzarIGuardar,
              style: _btnStyle(),
              child: const Text('Guardar i Finalitzar'),
            ),
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
          Text(value != null ? value.toStringAsFixed(1) : '-',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
