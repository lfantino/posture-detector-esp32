import 'dart:async';
import 'dart:math';

/// Aquest simulador imita les respostes de l'ESP32.
/// Emet 9 valors cada 500ms però aplicant petites oscil·lacions
/// perquè al fer la mitjana d'un minut els resultats vagin variant suaument
/// i l'usuari vegi canvis realistes i orgànics (en lloc d'un "50%" constant).
class FirmwareSimulator {
  final Random _random = Random();
  StreamController<List<double>>? _controller;
  Timer? _timer;

  // Variables per donar inèrcia/drifting natural a les dades
  double _timeParam = 0;
  List<double> _baseValues = List.filled(9, 60.0);
  bool _isSeated = false; 

  Stream<List<double>> get stream => _controller!.stream;

  void start() {
    _controller = StreamController<List<double>>.broadcast();
    
    // Per simular de tant en tant que l'usuari s'aixeca o s'asseu:
    // Aquí estem forçant "_isSeated = true" per la simulació d'estat per defecte.
    _isSeated = true;

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _controller!.add(_generateList());
    });
  }

  void stop() {
    _timer?.cancel();
    _controller?.close();
  }

  /// Alterna artificialment que l'usuari simulat s'aixequi o s'assegui (per proves UI)
  void toggleSubstate() {
    _isSeated = !_isSeated;
  }

  List<double> _generateList() {
    _timeParam += 0.1;
    List<double> updatedValues = [];

    for (int i = 0; i < 9; i++) {
      if (!_isSeated) {
        // Ningú assegut: Tots els sensors pràcticament llegeixen zèro.
        updatedValues.add(_random.nextDouble() * 2.0); 
      } else {
        // Moviment de sinus suau amb prou amplitud per creuar els llindars
        double drift = sin(_timeParam + i * 0.5) * 20; 
        // Soroll de lectura
        double noise = _random.nextDouble() * 10 - 5.0;
        
        // Base a 60 + corba + soroll
        double val = _baseValues[i] + drift + noise;
        
        // Clamping (Assegurar límits vàlids entre 0 i 100)
        if (val > 100) val = 100;
        if (val < 0) val = 0;

        updatedValues.add(val);
      }
    }
    return updatedValues;
  }
}
