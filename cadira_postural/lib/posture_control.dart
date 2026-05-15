import 'dart:async';
import 'package:flutter/material.dart';
import 'services/firmware_simulator.dart';
import 'services/bluetooth_service.dart';
import 'services/data_averager.dart';
import 'services/user_session.dart';
import 'database/database_helper.dart';
import 'services/notification_service.dart';
// BLOC 1
// ─── THRESHOLDS (canvia aquests valors quan tingueu dades reals) ──────────────

// Els thresholds ara resideixen dins de PostureController com a variables.
const double kMinPresioDeteccio = 10.0; // pressió mínima per detectar presència

// ─── FONT DE DADES ───────────────────────────────────────────────────────────
enum DataSource {
  bluetooth,  // Dades reals de l'ESP32 via Bluetooth Classic
  simulator,  // Dades simulades per proves sense hardware
}

// BLOC 2
// ─── POSTURE CONTROLLER ───────────────────────────────────────────────────────

class PostureController extends ChangeNotifier {
  // Patró Singleton
  static final PostureController _instance = PostureController._internal();
  static PostureController get instance => _instance;
  PostureController._internal() {
    // 1. Escoltem el flux ràpid per l'estat d'assegut i valors bruts
    _averager.rawStream.listen((values) {
      _rawValues = values;

      // Si acabem de canviar de font o encara està tot a zero, actualitzem la UI ràpidament
      bool isZero = _sensorValues.every((v) => v == 0.0);
      if (_needsImmediateUpdate || (isZero && hiHaAlgu)) {
        _sensorValues = List.from(values);
        _needsImmediateUpdate = false;
        notifyListeners();
      }

      bool presenciaActual = hiHaAlgu;

      if (presenciaActual && _iniciSessio == null) {
        // L'usuari s'acaba d'asseure!
        _iniciSessio = DateTime.now();
        _timerTemps = Timer.periodic(const Duration(seconds: 1), (_) {
          _tempsAssegut = DateTime.now().difference(_iniciSessio!);
          notifyListeners(); 
        });
        notifyListeners();
      } else if (!presenciaActual && _iniciSessio != null) {
        // L'usuari s'acaba d'aixecar!
        _tempsTotalAcumulat += _tempsAssegut;
        _tempsAssegut = Duration.zero;
        _iniciSessio = null;
        _timerTemps?.cancel();
        _guardarEstadistiquesDia();
        notifyListeners();
      }
    });

    // 2. Escoltem el flux mitjà lent per a la UI estable
    _averager.averagedStream.listen((values) {
      _sensorValues = values;
      
      if (hiHaAlgu) {
        _sumatoriPostura += bonPostura;
        _mostresPostura++;
        
        bool enAlerta = bonPostura < 0.7 || !culLateralOk || !culFrontalOk || !curvaturaCervicalLumbarOk;
        if (enAlerta && !_estavaEnAlerta) {
          _totalAlertesAvui++;
          _comprovarITriggerNotificacio();
        }
        _estavaEnAlerta = enAlerta;
      }
      
      notifyListeners(); 
    });
  }

  final FirmwareSimulator _simulator = FirmwareSimulator();
  final BluetoothService _bluetooth = BluetoothService.instance;
  final DataAverager _averager = DataAverager(limitBuffer: 10); // 5 sec for fast UI simulation

  bool _isStarted = false;
  bool _needsImmediateUpdate = false;
  DataSource _currentSource = DataSource.bluetooth;

  List<double> _sensorValues = List.filled(9, 0.0);
  List<double> _rawValues = List.filled(9, 0.0);

  Duration _tempsAssegut = Duration.zero;
  Duration _tempsTotalAcumulat =
      Duration.zero; // Acumulat de totes les sessions d'avui
  DateTime? _iniciSessio;
  Timer? _timerTemps;

  // Estadístiques diàries
  double _sumatoriPostura = 0.0;
  int _mostresPostura = 0;
  int _totalAlertesAvui = 0;
  bool _estavaEnAlerta = false;

  Future<void> _comprovarITriggerNotificacio() async {
    final userId = UserSession().userId;
    if (userId == null) return;
    
    final config = await DatabaseHelper().obtenirConfiguracio(userId);
    if (config != null && config['notificacions'] == 1) {
      await NotificationService.instance.showPostureAlert();
    }
  }

  Future<void> _guardarEstadistiquesDia() async {
    final userId = UserSession().userId;
    if (userId == null) return;
    
    double mitjana = 0.0;
    if (_mostresPostura > 0) {
      mitjana = (_sumatoriPostura / _mostresPostura) * 100.0;
    }
    
    await DatabaseHelper().desarEstadistiquesAvui(
      usuariId: userId,
      tempsCorrectedSeg: _tempsTotalAcumulat.inSeconds,
      posturaMitjaPercent: mitjana,
      totalAlertes: _totalAlertesAvui,
      correccions: 0,
    );
  }

  // ── Getters de l'estat de la font de dades ─────────────────────────────
  DataSource get currentSource => _currentSource;
  BluetoothService get bluetoothService => _bluetooth;

  // ── Thresholds (Dinàmics) ────────────────────────────────────────────────
  double maxDiferenciaLateralCul = 600.0; // Valor per defecte fins calibrar (rang FSR real: 0-4025)
  double maxDiferenciaFrontal = 600.0;
  double maxDistanciaCervical = 60.0;
  double maxDistanciaToracic = 60.0;
  double maxDistanciaLumbar = 60.0;
  double maxDiferenciaCervicalLumbar = 10.0;

  void loadThresholds({
    double? latCul,
    double? frontCul,
    double? distCerv,
    double? distTor,
    double? distLumb,
    double? diffCervLumb,
  }) {
    if (latCul != null) maxDiferenciaLateralCul = latCul;
    if (frontCul != null) maxDiferenciaFrontal = frontCul;
    if (distCerv != null) maxDistanciaCervical = distCerv;
    if (distTor != null) maxDistanciaToracic = distTor;
    if (distLumb != null) maxDistanciaLumbar = distLumb;
    if (diffCervLumb != null) maxDiferenciaCervicalLumbar = diffCervLumb;
    notifyListeners();
  }

  // Permet accedir a les dades immediates (sense suavitzar) per a la calibració
  List<double> get rawValues => _rawValues;

  // BLOC 3
  // ── Getters cojín culo (FSR 0-5) ─────────────────────────────────────────

  double get fsrCulDarrereEsq => _sensorValues[0];
  double get fsrCulDarrereDret => _sensorValues[1];
  double get fsrCulMigEsq => _sensorValues[2];
  double get fsrCulMigDret => _sensorValues[3];
  double get fsrCulDavantEsq => _sensorValues[4];
  double get fsrCulDavantDret => _sensorValues[5];

  // ── Getters ultrasonidos (6-8) ──────────────────────────────────────────

  double get usCervical => _sensorValues[6];
  double get usToracic => _sensorValues[7];
  double get usLumbar => _sensorValues[8];

  // BLOC 4
  // ── Detecció de presència ─────────────────────────────────────────────────
  // Considera que algú seu si almenys un FSR del cul supera el mínim

  bool get hiHaAlgu =>
      _rawValues[0] > kMinPresioDeteccio ||
      _rawValues[1] > kMinPresioDeteccio ||
      _rawValues[2] > kMinPresioDeteccio ||
      _rawValues[3] > kMinPresioDeteccio ||
      _rawValues[4] > kMinPresioDeteccio ||
      _rawValues[5] > kMinPresioDeteccio;

  // BLOC 5
  // ── Anàlisi cojín culo ────────────────────────────────────────────────────

  // Simetria lateral: promedio esquerra vs dreta
  double get _pressioCulEsq =>
      (fsrCulDavantEsq + fsrCulMigEsq + fsrCulDarrereEsq) / 3;
  double get _pressioCulDret =>
      (fsrCulDavantDret + fsrCulMigDret + fsrCulDarrereDret) / 3;
  double get diferenciaCulLateral => (_pressioCulEsq - _pressioCulDret).abs();
  bool get culLateralOk => diferenciaCulLateral <= maxDiferenciaLateralCul;

  // Públics per a la UI (saber quin costat pesa més)
  double get pressioCulEsq => _pressioCulEsq;
  double get pressioCulDret => _pressioCulDret;

  // Públics per a la UI (saber quina fila pesa més)
  double get pressioCulDavant => _pressioCulDavant;
  double get pressioCulDarrere => _pressioCulDarrere;

  // Simetria frontal: promedio davant vs darrere (ignorant la fila del mig)
  double get _pressioCulDavant => (fsrCulDavantEsq + fsrCulDavantDret) / 2;
  double get _pressioCulDarrere => (fsrCulDarrereEsq + fsrCulDarrereDret) / 2;
  double get diferenciaCulFrontal =>
      (_pressioCulDavant - _pressioCulDarrere).abs();
  bool get culFrontalOk => diferenciaCulFrontal <= maxDiferenciaFrontal;

  // BLOC 7
  // ── Anàlisi ultrasonidos ──────────────────────────────────────────────────
  // Els ultrasonidos mesuren distància en cm
  // Si la distància és molt gran, la persona s'ha allunyat del respatller

  bool get cervicalOk => usCervical <= maxDistanciaCervical;
  bool get toracicOk => usToracic <= maxDistanciaToracic;
  bool get lumbarOk => usLumbar <= maxDistanciaLumbar;

  // Comparació de curvatura: diferència entre zona cervical i lumbar
  double get diferenciaCervicalLumbar => (usCervical - usLumbar).abs();
  bool get curvaturaCervicalLumbarOk =>
      diferenciaCervicalLumbar <= maxDiferenciaCervicalLumbar;

  // Helpers per l'estat individual dels sensors (per la UI de punts verd/vermell)
  double getSensorValue(int index) {
    if (index >= 0 && index < _sensorValues.length) {
      return _sensorValues[index];
    }
    return 0.0;
  }

  bool isSensorOk(int index) {
    if (index >= 0 && index <= 5) {
      // Seient (FSR 0-5)
      // Per simplicitat, el considerem OK si no està en un desequilibri lateral/frontal global,
      // o individualment podríem checkejar si s'escapa de la mitjana.
      // Per ara usem el criteri global del grup per pintar-los.
      return culLateralOk && culFrontalOk;
    }
    if (index == 6) return cervicalOk;
    if (index == 7) return toracicOk;
    if (index == 8) return lumbarOk;
    return true;
  }

  // BLOC 8
  // ── Postura global ────────────────────────────────────────────────────────
  // Combina els 6 criteris de postura per donar una puntuació de 0.0 a 1.0
  double get bonPostura {
    int correctes = 0;
    if (culLateralOk) correctes++;
    if (culFrontalOk) correctes++;
    if (cervicalOk) correctes++;
    if (toracicOk) correctes++;
    if (lumbarOk) correctes++;
    if (curvaturaCervicalLumbarOk) correctes++;

    return correctes / 6;
  }

  // BLOC 9
  // ── Temps assegut ────────────────────────────────────────────────────────────

  // Per a la sessió actual
  String get tempsAssegutFormatat {
    int hores = _tempsAssegut.inMinutes ~/ 60;
    int minuts = _tempsAssegut.inMinutes % 60;
    return hores > 0 ? '${hores}h ${minuts}m' : '${minuts}m';
  }

  int get minutsAssegut => _tempsAssegut.inMinutes;

  // Per al total del dia
  String get tempsAssegutTotalFormatat {
    Duration total = _tempsAssegut + _tempsTotalAcumulat;
    int hores = total.inMinutes ~/ 60;
    int minuts = total.inMinutes % 60;
    return hores > 0 ? '${hores}h ${minuts}m' : '${minuts}m';
  }

  int get minutsAssegutTotal => (_tempsAssegut + _tempsTotalAcumulat).inMinutes;

  // BLOC 10
  // ── Inici i parada ───────────────────────────────────────────────────────────

  /// Canvia la font de dades. Si ja estava iniciat, para i reinicia amb la nova font.
  Future<void> switchSource(DataSource source) async {
    if (_currentSource == source && _isStarted) return;
    
    // Aturar la font anterior
    if (_isStarted) {
      _stopSource();
    }
    
    _currentSource = source;
    _needsImmediateUpdate = true; // Forçarem que el primer paquet de la nova font es vegi ja
    
    // Reiniciar amb la nova font
    start();
    notifyListeners();
  }

  void start() {
    if (_isStarted) return; // Evitem duplicar subscripcions
    _isStarted = true;

    Stream<List<double>> sourceStream;

    if (_currentSource == DataSource.simulator) {
      // Mode simulador: usar el FirmwareSimulator local
      _simulator.start();
      sourceStream = _simulator.stream;
      debugPrint('[PostureCtrl] Iniciat amb SIMULADOR');
    } else {
      // Mode Bluetooth: usar el BluetoothService
      sourceStream = _bluetooth.stream;
      debugPrint('[PostureCtrl] Iniciat amb BLUETOOTH');
      
      if (!_bluetooth.isConnected) {
        _bluetooth.autoConnect();
      }
    }

    _averager.connectTo(sourceStream);
  }

  /// Atura la font de dades actual sense tancar l'averager streams.
  void _stopSource() {
    if (_currentSource == DataSource.simulator) {
      _simulator.stop();
    }
    // El Bluetooth no s'atura automàticament (la connexió es manté)
    _averager.stop();
    _timerTemps?.cancel();
    _isStarted = false;
  }

  void stop() {
    _stopSource();
    if (_currentSource == DataSource.bluetooth) {
      _bluetooth.stop();
    }
  }
}
