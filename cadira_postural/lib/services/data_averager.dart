import 'dart:async';

/// `DataAverager` fa d'intermediari (Middleware).
/// Escolta un origen d'alta freqüència (p. ex. 500ms del firmware) i:
/// 1. Exposa `rawStream`: El mateix flux d'alta velocitat per detectar coses instantànies (com saltar de la cadira en temps real).
/// 2. Exposa `averagedStream`: Flux lent (per defecte 1 minut / 120 dades) que fa la mitjana
///    exacta per alimentar els colors i les analítiques sense cremar bateria o posar nerviós l'usuari visualment.
class DataAverager {
  final StreamController<List<double>> _averagedController = StreamController<List<double>>.broadcast();
  final StreamController<List<double>> _rawController = StreamController<List<double>>.broadcast();

  Stream<List<double>> get averagedStream => _averagedController.stream;
  Stream<List<double>> get rawStream => _rawController.stream;

  final List<List<double>> _buffer = [];
  StreamSubscription<List<double>>? _subscription;
  
  // 120 cicles a 500ms cadascun són exactament 60.000ms = 60 segons (1 minut)
  final int limitBuffer;

  DataAverager({this.limitBuffer = 120});

  /// Connecta i arrenca l'intermediari rebent dades de la subscripció (Firmware/Bluetooth).
  void connectTo(Stream<List<double>> sourceStream) {
    _subscription = sourceStream.listen((data) {
      // 1. Enviament immediat en temps real (per a la detecció de seure/aixecar).
      _rawController.add(data);

      // 2. Emmagatzematge per calcular el minut posterior.
      _buffer.add(data);

      if (_buffer.length >= limitBuffer) {
        _emitAverage();
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _averagedController.close();
    _rawController.close();
  }

  /// Calcula manualment la meitat i en fa broadcast a tothom qui miri el `averagedStream`.
  void _emitAverage() {
    if (_buffer.isEmpty) return;

    int numSensors = _buffer.first.length; // Habitualment 15
    List<double> averages = List.filled(numSensors, 0.0);

    for (int col = 0; col < numSensors; col++) {
      double sum = 0;
      for (int row = 0; row < _buffer.length; row++) {
        sum += _buffer[row][col];
      }
      averages[col] = sum / _buffer.length;
    }

    _averagedController.add(averages);
    _buffer.clear(); // Buidem la cistella per tornar a capturar el pròxim minut.
  }
}
