import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── MAPEO JSON → ÍNDEX DE LA LLISTA DE 9 VALORS ───────────────────────────
//
// El firmware (main_v2.ino) emet dos tipus de missatge via BluetoothSerial:
//
//   A) Silla OCUPADA  → cada 500 ms:
//      {
//        "fsrDavantEsq":312, "fsrDavantDret":287,
//        "fsrMigEsq":301,    "fsrMigDret":290,
//        "fsrDarrereEsq":278,"fsrDarrereDret":265,
//        "usCervical":14.2, "usToracic":18.5, "usLumbar":12.1
//      }
//
//   B) Silla BUIDA   → cada 10 s:
//      { "estat": "buida" }
//
// La llista de sortida té sempre 9 posicions:
//   índex 0 → fsrDarrereEsq       índex 1 → fsrDarrereDret
//   índex 2 → fsrMigEsq           índex 3 → fsrMigDret
//   índex 4 → fsrDavantEsq        índex 5 → fsrDavantDret
//   índex 6 → usCervical          índex 7 → usToracic
//   índex 8 → usLumbar
//
// Quan la silla és buida s'emeten 9 zeros, cosa que és compatible
// amb el getter hiHaAlgu del PostureController (BLOC 4).
// ─────────────────────────────────────────────────────────────────────────────

/// Claus del JSON del firmware, en ordre, que s'han de mapejar als 9 índexos.
const List<String> _kJsonKeys = [
  'fsrDarrereEsq',  // [0]
  'fsrDarrereDret', // [1]
  'fsrMigEsq',      // [2]
  'fsrMigDret',     // [3]
  'fsrDavantEsq',   // [4]
  'fsrDavantDret',  // [5]
  'usCervical',     // [6]
  'usToracic',      // [7]
  'usLumbar',       // [8]
];

/// Nom Bluetooth que el firmware (main_v2.ino) registra: SerialBT.begin("Cadira_Postural")
const String kEsp32DeviceName = 'Cadira_Postural';

/// Estats possibles de la connexió Bluetooth.
enum BtConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// `BluetoothService`
///
/// Gestiona la connexió Bluetooth Classic (SPP/RFCOMM) amb l'ESP32
/// i tradueix cada línia JSON a una `List<double>` de 9 valors.
///
/// Ús:
/// ```dart
/// final bt = BluetoothService.instance;
/// await bt.start();
/// bt.stream.listen((values) => print(values));
/// ```
class BluetoothService {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final BluetoothService _instance = BluetoothService._internal();
  static BluetoothService get instance => _instance;
  BluetoothService._internal();

  final FlutterBlueClassic _plugin = FlutterBlueClassic();

  BluetoothConnection? _connection;
  StreamSubscription? _inputSubscription;

  final StreamController<List<double>> _controller =
      StreamController<List<double>>.broadcast();

  /// Buffer intern per acumular fragments de text entre events del socket.
  final StringBuffer _lineBuffer = StringBuffer();

  /// Estat de la connexió observable per la UI.
  final ValueNotifier<BtConnectionState> connectionState =
      ValueNotifier(BtConnectionState.disconnected);

  /// Últim missatge d'error (per mostrar a la UI).
  String? lastError;

  /// Adreça MAC del dispositiu connectat (per mostrar a la UI).
  String? connectedDeviceAddress;

  // ── API Pública ────────────────────────────────────────────────────────

  /// Stream de llistes de 9 valors (un per missatge JSON complet rebut).
  Stream<List<double>> get stream => _controller.stream;

  /// `true` si hi ha connexió Bluetooth activa.
  bool get isConnected => _connection?.isConnected ?? false;

  /// Demana els permisos necessaris per Bluetooth a Android.
  /// Retorna `true` si tots els permisos han estat concedits.
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every(
      (s) => s.isGranted || s.isLimited,
    );
  }

  /// Obté la llista de dispositius emparellats (paired).
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final devices = await _plugin.bondedDevices;
      return devices ?? [];
    } catch (e) {
      debugPrint('[BT] Error obtenint dispositius emparellats: $e');
      return [];
    }
  }

  /// Busca l'ESP32 entre els dispositius emparellats pel nom "Cadira_Postural"
  /// i s'hi connecta automàticament.
  Future<bool> autoConnect() async {
    final granted = await requestPermissions();
    if (!granted) {
      lastError = 'Permisos Bluetooth no concedits';
      connectionState.value = BtConnectionState.error;
      return false;
    }

    connectionState.value = BtConnectionState.scanning;

    try {
      final devices = await getBondedDevices();
      final esp32 = devices.where(
        (d) => d.name?.contains(kEsp32DeviceName) == true,
      );

      if (esp32.isEmpty) {
        lastError = 'No s\'ha trobat "$kEsp32DeviceName" entre els dispositius emparellats.\n'
            'Ves a Ajustos → Bluetooth del telèfon i vincula l\'ESP32 primer.';
        connectionState.value = BtConnectionState.error;
        return false;
      }

      return await connectToDevice(esp32.first.address);
    } catch (e) {
      lastError = 'Error durant la connexió automàtica: $e';
      connectionState.value = BtConnectionState.error;
      return false;
    }
  }

  /// Connecta a un dispositiu per la seva adreça MAC.
  Future<bool> connectToDevice(String address) async {
    connectionState.value = BtConnectionState.connecting;
    lastError = null;

    try {
      _connection = await _plugin.connect(address);

      if (_connection == null || !_connection!.isConnected) {
        lastError = 'No s\'ha pogut establir la connexió amb $address';
        connectionState.value = BtConnectionState.error;
        return false;
      }

      connectedDeviceAddress = address;
      connectionState.value = BtConnectionState.connected;

      // Escoltar les dades entrants
      _inputSubscription = _connection!.input?.listen(
        _onRawBytes,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('[BT] Connectat a $address');
      return true;
    } catch (e) {
      lastError = 'Error connectant a $address: $e';
      connectionState.value = BtConnectionState.error;
      debugPrint('[BT] $lastError');
      return false;
    }
  }

  /// Tanca la connexió i neteja els recursos.
  Future<void> stop() async {
    _inputSubscription?.cancel();
    _inputSubscription = null;
    _connection?.dispose();
    _connection = null;
    _lineBuffer.clear();
    connectedDeviceAddress = null;
    connectionState.value = BtConnectionState.disconnected;
    debugPrint('[BT] Connexió tancada');
  }

  /// Tanca la connexió i el stream completament (per quan l'app es destrueix).
  Future<void> dispose() async {
    await stop();
    if (!_controller.isClosed) _controller.close();
  }

  // ── Lògica de parsing (privada) ─────────────────────────────────────────

  /// Rep bytes crus del Bluetooth i els converteix a text UTF-8.
  void _onRawBytes(Uint8List bytes) {
    try {
      final chunk = utf8.decode(bytes);
      _onRawData(chunk);
    } catch (e) {
      debugPrint('[BT] Error decodificant bytes: $e');
    }
  }

  /// Rep fragments de text cru. El firmware pot tallar el JSON en múltiples
  /// paquets BT, per això acumulem fins a trobar el '\n' final.
  void _onRawData(String chunk) {
    _lineBuffer.write(chunk);
    final fullText = _lineBuffer.toString();

    int newlineIndex;
    String remaining = fullText;

    // Processar totes les línies completes que hi hagi al buffer
    while ((newlineIndex = remaining.indexOf('\n')) != -1) {
      final line = remaining.substring(0, newlineIndex).trim();
      remaining = remaining.substring(newlineIndex + 1);

      if (line.isNotEmpty) {
        _parseLine(line);
      }
    }

    // Guardar el fragment parcial que no té '\n' encara
    _lineBuffer
      ..clear()
      ..write(remaining);
  }

  /// Parseja una línia JSON completa i emet la List<double> corresponent.
  void _parseLine(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;

      // Cas B: silla buida → emetre 9 zeros
      if (json['estat'] == 'buida') {
        _emit(List<double>.filled(9, 0.0));
        return;
      }

      // Cas A: dades normals → mapejar cada clau al seu índex
      final List<double> values = _kJsonKeys.map((key) {
        final raw = json[key];
        if (raw == null) return 0.0;
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw.toString()) ?? 0.0;
      }).toList();

      _emit(values);
    } catch (_) {
      // JSON malmès o missatge desconegut: s'ignora silenciosament.
      // Un paquet corrupte puntual no ha d'aturar el stream.
    }
  }

  void _emit(List<double> values) {
    if (!_controller.isClosed) _controller.add(values);
  }

  void _onError(dynamic error) {
    debugPrint('[BT] Error de transport: $error');
    lastError = 'Error de connexió: $error';
    connectionState.value = BtConnectionState.error;
    // Emetem zeros per indicar pèrdua de senyal
    _emit(List<double>.filled(9, 0.0));
  }

  void _onDone() {
    debugPrint('[BT] Connexió tancada pel firmware o timeout');
    if (connectionState.value == BtConnectionState.connected) {
      lastError = 'La connexió s\'ha perdut. Prova de reconnectar.';
      connectionState.value = BtConnectionState.disconnected;
    }
    _emit(List<double>.filled(9, 0.0));
  }
}
