import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// ─── MAPEO JSON → ÍNDEX DE LA LLISTA DE 9 VALORS ───────────────────────────
//
// El firmware (main.ino) emet dos tipus de missatge via BluetoothSerial:
//
//   A) Silla OCUPADA  → cada 500 ms:
//      {
//        "fsrCulDavantEsq":312, "fsrCulDavantDret":287,
//        "fsrCulMigEsq":301,    "fsrCulMigDret":290,
//        "fsrCulDarrereEsq":278,"fsrCulDarrereDret":265,
//        "fsrEsquenaAltEsq":50, "fsrEsquenaAltDret":48,   ← ignorats aquí
//        "fsrEsquenaMigEsq":60, "fsrEsquenaMigDret":55,   ← ignorats aquí
//        "fsrEsquenaBaixEsq":70,"fsrEsquenaBaixDret":68,  ← ignorats aquí
//        "usCervical":14.2, "usToracic":18.5, "usLumbar":12.1
//      }
//
//   B) Silla BUIDA   → cada 10 s:
//      { "estat": "buida" }
//
// La llista de sortida té sempre 9 posicions:
//   índex 0 → fsrCulDarrereEsq    índex 1 → fsrCulDarrereDret
//   índex 2 → fsrCulMigEsq        índex 3 → fsrCulMigDret
//   índex 4 → fsrCulDavantEsq     índex 5 → fsrCulDavantDret
//   índex 6 → usCervical          índex 7 → usToracic
//   índex 8 → usLumbar
//
// Quan la silla és buida s'emeten 9 zeros, cosa que és compatible
// amb el getter hiHaAlgu del PostureController (BLOC 4).
// ─────────────────────────────────────────────────────────────────────────────

/// Claus del JSON del firmware, en ordre, que s'han de mapejar als 9 índexos.
const List<String> _kJsonKeys = [
  'fsrCulDarrereEsq',  // [0]
  'fsrCulDarrereDret', // [1]
  'fsrCulMigEsq',      // [2]
  'fsrCulMigDret',     // [3]
  'fsrCulDavantEsq',   // [4]
  'fsrCulDavantDret',  // [5]
  'usCervical',        // [6]
  'usToracic',         // [7]
  'usLumbar',          // [8]
];

/// `BluetoothParser`
///
/// Connecta a l'ESP32 via Bluetooth Classic (SPP/RFCOMM) i tradueix
/// cada línia JSON que arriba a una `List<double>` de 9 valors.
///
/// Ús:
/// ```dart
/// final parser = BluetoothParser(deviceAddress: 'XX:XX:XX:XX:XX:XX');
/// await parser.start();
///
/// parser.stream.listen((List<double> values) {
///   print(values); // [fsrCulDarrereEsq, ..., usLumbar]
/// });
///
/// // Quan acabis:
/// await parser.stop();
/// ```
class BluetoothParser {
  /// Adreça MAC de l'ESP32 paired al dispositiu (ex: 'DC:54:75:C2:3E:1A').
  final String deviceAddress;

  BluetoothConnection? _connection;

  final StreamController<List<double>> _controller =
      StreamController<List<double>>.broadcast();

  /// Buffer intern per acumular fragments de text entre events del socket.
  /// El firmware envia JSON seguit d'un '\n' (via println).
  final StringBuffer _lineBuffer = StringBuffer();

  BluetoothParser({required this.deviceAddress});

  // ── API pública ──────────────────────────────────────────────────────────

  /// Stream de llistes de 9 valors (un per missatge JSON complet rebut).
  Stream<List<double>> get stream => _controller.stream;

  /// `true` si hi ha connexió Bluetooth activa.
  bool get isConnected => _connection?.isConnected ?? false;

  /// Connecta a l'ESP32 i comença a escoltar.
  /// Llança una excepció si no es pot connectar (dispositiu no visible, no paired...).
  Future<void> start() async {
    _connection = await BluetoothConnection.toAddress(deviceAddress);

    _connection!.input!
        .transform(utf8.decoder)   // bytes → String
        .listen(
          _onRawData,
          onError: _onError,
          onDone: _onDone,
          cancelOnError: false,
        );
  }

  /// Tanca la connexió i el stream.
  Future<void> stop() async {
    await _connection?.close();
    if (!_controller.isClosed) _controller.close();
  }

  // ── Lògica de parsing (privada) ───────────────────────────────────────────

  /// Rep fragments de text cru. El firmware pot tallar el JSON en múltiples
  /// paquets TCP/BT, per això acumulem fins a trobar el '\n' final.
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
    // Error de transport: emetre zeros i tancar
    _emit(List<double>.filled(9, 0.0));
    if (!_controller.isClosed) _controller.close();
  }

  void _onDone() {
    // Connexió tancada pel firmware o per timeout
    _emit(List<double>.filled(9, 0.0));
    if (!_controller.isClosed) _controller.close();
  }
}
