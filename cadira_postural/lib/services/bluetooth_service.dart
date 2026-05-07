import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── UUIDs del Nordic UART Service (NUS) ────────────────────────────────────
//
// El firmware (main_v2.ino) implementa el NUS per emular una UART sobre BLE.
// Mateixos UUIDs que el firmware.
//
//   TX Characteristic (Notify → App): ESP32 envia les dades JSON
//   RX Characteristic (Write → ESP32): l'App podria enviar comandes (no usat ara)
//
const String _kNusServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String _kNusTxCharUuid  = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // Notify

// ─── MAPEO JSON → ÍNDEX DE LA LLISTA DE 9 VALORS ────────────────────────────
//
// El firmware emet dos tipus de missatge via BLE:
//
//   A) Silla OCUPADA  → cada 500 ms:
//      { "fsrDavantEsq":312, "fsrDavantDret":287,
//        "fsrMigEsq":301,    "fsrMigDret":290,
//        "fsrDarrereEsq":278,"fsrDarrereDret":265,
//        "usCervical":14.2,  "usToracic":18.5, "usLumbar":12.1 }
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
// Quan la silla és buida s'emeten 9 zeros (compatible amb hiHaAlgu).
// ─────────────────────────────────────────────────────────────────────────────

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

/// Nom BLE que el firmware registra: BLEDevice::init("Cadira_Postural")
const String kEsp32DeviceName = 'Cadira_Postural';

/// Estats possibles de la connexió BLE.
enum BtConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// `BluetoothService`
///
/// Gestiona la connexió BLE (Nordic UART Service) amb l'ESP32-C5
/// i tradueix cada línia JSON a una `List<double>` de 9 valors.
///
/// Ús:
/// ```dart
/// final bt = BluetoothService.instance;
/// await bt.autoConnect();
/// bt.stream.listen((values) => print(values));
/// ```
class BluetoothService {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final BluetoothService _instance = BluetoothService._internal();
  static BluetoothService get instance => _instance;
  BluetoothService._internal();

  BluetoothDevice?         _device;
  StreamSubscription?      _notifySubscription;
  StreamSubscription?      _connectionSubscription;

  final StreamController<List<double>> _controller =
      StreamController<List<double>>.broadcast();

  /// Buffer intern per acumular fragments BLE fins al '\n' final.
  final StringBuffer _lineBuffer = StringBuffer();

  /// Estat de la connexió observable per la UI.
  final ValueNotifier<BtConnectionState> connectionState =
      ValueNotifier(BtConnectionState.disconnected);

  /// Últim missatge d'error (per mostrar a la UI).
  String? lastError;

  /// Adreça del dispositiu connectat (per mostrar a la UI).
  String? connectedDeviceAddress;

  // ── API Pública ────────────────────────────────────────────────────────

  /// Stream de llistes de 9 valors (un per missatge JSON complet rebut).
  Stream<List<double>> get stream => _controller.stream;

  /// `true` si hi ha connexió BLE activa.
  bool get isConnected => _device?.isConnected ?? false;

  /// Demana els permisos necessaris per BLE a Android.
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return false;
    }
    
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Escaneja i connecta automàticament al primer "Cadira_Postural" trobat.
  Future<bool> autoConnect() async {
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      lastError = 'Bluetooth no està suportat a Windows. Fes servir el Simulador.';
      connectionState.value = BtConnectionState.error;
      return false;
    }

    final granted = await requestPermissions();
    if (!granted) {
      lastError = 'Permisos Bluetooth no concedits';
      connectionState.value = BtConnectionState.error;
      return false;
    }

    connectionState.value = BtConnectionState.scanning;
    lastError = null;

    try {
      // Escaneig filtrat pel nom, timeout 10 s
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withNames: [kEsp32DeviceName],
      );

      BluetoothDevice? found;
      // Escoltam els resultats fins trobar el dispositiu o fins al timeout
      await for (final results in FlutterBluePlus.scanResults) {
        for (final r in results) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName;
          if (name.contains(kEsp32DeviceName)) {
            found = r.device;
            break;
          }
        }
        if (found != null) break;
      }

      await FlutterBluePlus.stopScan();

      if (found == null) {
        lastError = 'No s\'ha trobat "$kEsp32DeviceName".\n'
            'Comprova que l\'ESP32-C5 és encès i a prop.';
        connectionState.value = BtConnectionState.error;
        return false;
      }

      return await connectToDevice(found);
    } catch (e) {
      await FlutterBluePlus.stopScan();
      lastError = 'Error durant l\'escaneig: $e';
      connectionState.value = BtConnectionState.error;
      debugPrint('[BLE] $lastError');
      return false;
    }
  }

  /// Connecta a un dispositiu BLE concret, descobreix el servei NUS
  /// i subscriu a les notificacions de la característica TX.
  Future<bool> connectToDevice(BluetoothDevice device) async {
    connectionState.value = BtConnectionState.connecting;
    lastError = null;

    try {
      await device.connect(autoConnect: false);
      _device = device;
      connectedDeviceAddress = device.remoteId.str;

      // Monitoritzar desconnexions inesperades
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('[BLE] Dispositiu desconnectat');
          if (connectionState.value == BtConnectionState.connected) {
            lastError = 'La connexió s\'ha perdut. Toca per reconnectar.';
            connectionState.value = BtConnectionState.disconnected;
          }
          _emit(List<double>.filled(9, 0.0));
        }
      });

      // Descobrir serveis BLE
      final services = await device.discoverServices();
      BluetoothCharacteristic? txChar;

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == _kNusServiceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _kNusTxCharUuid) {
              txChar = char;
              break;
            }
          }
          break;
        }
      }

      if (txChar == null) {
        lastError = 'No s\'ha trobat el servei NUS al dispositiu.\n'
            'Comprova que el firmware és la versió BLE (main_v2.ino).';
        connectionState.value = BtConnectionState.error;
        await device.disconnect();
        return false;
      }

      // Activar notificacions BLE
      await txChar.setNotifyValue(true);

      // Subscriure al flux de dades entrants
      _notifySubscription = txChar.onValueReceived.listen(
        _onBleBytes,
        onError: _onError,
      );
      device.cancelWhenDisconnected(_notifySubscription!);

      connectionState.value = BtConnectionState.connected;
      debugPrint('[BLE] Connectat a ${device.remoteId.str}');
      return true;
    } catch (e) {
      lastError = 'Error connectant: $e';
      connectionState.value = BtConnectionState.error;
      debugPrint('[BLE] $lastError');
      return false;
    }
  }

  /// Tanca la connexió i neteja els recursos.
  Future<void> stop() async {
    _notifySubscription?.cancel();
    _notifySubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _device?.disconnect();
    _device = null;
    _lineBuffer.clear();
    connectedDeviceAddress = null;
    connectionState.value = BtConnectionState.disconnected;
    debugPrint('[BLE] Connexió tancada');
  }

  /// Tanca la connexió i el stream completament (per quan l'app es destrueix).
  Future<void> dispose() async {
    await stop();
    if (!_controller.isClosed) _controller.close();
  }

  // ── Lògica de parsing (privada) — idèntica a la versió Classic ─────────
  //
  // El firmware envia el JSON fragmentat en chunks de 20 bytes via BLE Notify.
  // El '\n' al final del darrer fragment és el delimitador de missatge.

  /// Rep bytes BLE crus i els converteix a text UTF-8.
  void _onBleBytes(List<int> bytes) {
    try {
      final chunk = utf8.decode(bytes);
      _onRawData(chunk);
    } catch (e) {
      debugPrint('[BLE] Error decodificant bytes: $e');
    }
  }

  /// Acumula fragments de text fins a trobar el '\n' i parseja cada línia completa.
  void _onRawData(String chunk) {
    _lineBuffer.write(chunk);
    final fullText = _lineBuffer.toString();

    int newlineIndex;
    String remaining = fullText;

    while ((newlineIndex = remaining.indexOf('\n')) != -1) {
      final line = remaining.substring(0, newlineIndex).trim();
      remaining = remaining.substring(newlineIndex + 1);
      if (line.isNotEmpty) _parseLine(line);
    }

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
      // JSON malmès o paquet fragmentat puntual: s'ignora silenciosament.
    }
  }

  void _emit(List<double> values) {
    if (!_controller.isClosed) _controller.add(values);
  }

  void _onError(dynamic error) {
    debugPrint('[BLE] Error de transport: $error');
    lastError = 'Error de connexió: $error';
    connectionState.value = BtConnectionState.error;
    _emit(List<double>.filled(9, 0.0));
  }
}
