import 'package:flutter/material.dart';
import 'sensor_simulator.dart';

// ─── THRESHOLDS (canvia aquests valors quan tingueu dades reals) ──────────────

const double kMaxDiferenciaLateral = 20.0;  // diferència màx entre esquerra i dreta (0-100)
const double kMaxDiferenciaFrontal = 25.0;  // diferència màx entre davant i darrere (0-100)
const double kMinPresioDeteccio    = 10.0;  // pressió mínima per detectar que algú seu (0-100)

// ─── POSTURE CONTROLLER ───────────────────────────────────────────────────────

class PostureController extends ChangeNotifier {
  final SensorSimulator _simulator = SensorSimulator();

  // Llista crua de 11 valors del simulador (o del ESP32 en el futur)
  List<double> _sensorValues = List.filled(11, 0.0);

  // Temps assegut calculat per la pròpia app (no ve del sensor)
  Duration _tempsAssegut = Duration.zero;
  DateTime? _iniciSessio;
  Timer? _timerTemps;

  // ── Getters de sensors individuals ──────────────────────────────────────────

  // Coixí cul (FSR)
  double get fsrCulDavantEsq  => _sensorValues[0];
  double get fsrCulDavantDret  => _sensorValues[1];
  double get fsrCulDarrereEsq => _sensorValues[2];
  double get fsrCulDarrereDret => _sensorValues[3];

  // Coixí esquena (FSR)
  double get fsrEsquenaAltEsq  => _sensorValues[4];
  double get fsrEsquenaAltDret  => _sensorValues[5];
  double get fsrEsquenaBaixEsq => _sensorValues[6];
  double get fsrEsquenaBaixDret => _sensorValues[7];

  // Ultrasonits
  double get us1 => _sensorValues[8];
  double get us2 => _sensorValues[9];
  double get us3 => _sensorValues[10];

  // ── Detecció de presència ────────────────────────────────────────────────────
  // Considera que algú seu si almenys un FSR del cul supera el mínim
  bool get hiHaAlgu =>
      fsrCulDavantEsq  > kMinPresioDeteccio ||
      fsrCulDavantDret  > kMinPresioDeteccio ||
      fsrCulDarrereEsq > kMinPresioDeteccio ||
      fsrCulDarrereDret > kMinPresioDeteccio;

  // ── Anàlisi de postura del coixí del cul ────────────────────────────────────

  // Simetria lateral cul: diferència entre costat esquerre i dret
  double get _pressioCulEsq  => (fsrCulDavantEsq  + fsrCulDarrereEsq) / 2;
  double get _pressioCulDret  => (fsrCulDavantDret  + fsrCulDarrereDret) / 2;
  double get diferenciaCulLateral => (_pressioCulEsq - _pressioCulDret).abs();
  bool get culLateralOk => diferenciaCulLateral <= kMaxDiferenciaLateral;

  // Simetria frontal cul: diferència entre davant i darrere
  double get _pressioCulDavant => (fsrCulDavantEsq + fsrCulDavantDret) / 2;
  double get _pressioCulDarrere => (fsrCulDarrereEsq + fsrCulDarrereDret) / 2;
  double get diferenciaCulFrontal => (_pressioCulDavant - _pressioCulDarrere).abs();
  bool get culFrontalOk => diferenciaCulFrontal <= kMaxDiferenciaFrontal;

  // ── Anàlisi de postura del coixí de l'esquena ────────────────────────────────

  // Simetria lateral esquena: diferència entre costat esquerre i dret
  double get _pressioEsquenaEsq  => (fsrEsquenaAltEsq  + fsrEsquenaBaixEsq) / 2;
  double get _pressioEsquenaDret  => (fsrEsquenaAltDret  + fsrEsquenaBaixDret) / 2;
  double get diferenciaEsquenaLateral => (_pressioEsquenaEsq - _pressioEsquenaDret).abs();
  bool get esquenaLateralOk => diferenciaEsquenaLateral <= kMaxDiferenciaLateral;

  // Simetria frontal esquena: diferència entre part alta i baixa
  double get _pressioEsquenaAlt  => (fsrEsquenaAltEsq  + fsrEsquenaAltDret) / 2;
  double get _pressioEsquenaBaix => (fsrEsquenaBaixEsq + fsrEsquenaBaixDret) / 2;
  double get diferenciaEsquenaVertical => (_pressioEsquenaAlt - _pressioEsquenaBaix).abs();
  bool get esquenaVerticalOk => diferenciaEsquenaVertical <= kMaxDiferenciaFrontal;

  // ── Postura global ───────────────────────────────────────────────────────────
  // Combina els 4 criteris: lateral cul, frontal cul, lateral esquena, vertical esquena
  double get bonPostura {
    int correctes = 0;
    if (culLateralOk)      correctes++;
    if (culFrontalOk)      correctes++;
    if (esquenaLateralOk)  correctes++;
    if (esquenaVerticalOk) correctes++;
    return correctes / 4;
  }

  // ── Temps assegut ────────────────────────────────────────────────────────────
  String get tempsAssegutFormatat {
    int hores  = _tempsAssegut.inMinutes ~/ 60;
    int minuts = _tempsAssegut.inMinutes % 60;
    return hores > 0 ? '${hores}h ${minuts}m' : '${minuts}m';
  }

  int get minutsAssegut => _tempsAssegut.inMinutes;

  // ── Inici i parada ───────────────────────────────────────────────────────────
  void start() {
    _simulator.start();
    _simulator.stream.listen((values) {
      _sensorValues = values;

      // Gestiona el timer de temps assegut segons si hi ha algú
      if (hiHaAlgu && _iniciSessio == null) {
        _iniciSessio = DateTime.now();
        _timerTemps = Timer.periodic(const Duration(seconds: 1), (_) {
          _tempsAssegut = DateTime.now().difference(_iniciSessio!);
          notifyListeners();
        });
      } else if (!hiHaAlgu && _iniciSessio != null) {
        _iniciSessio = null;
        _timerTemps?.cancel();
      }

      notifyListeners();
    });
  }

  void stop() {
    _simulator.stop();
    _timerTemps?.cancel();
  }
}