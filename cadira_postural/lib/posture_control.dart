import 'package:flutter/material.dart';
import 'sensor_simulator.dart';

class PostureController extends ChangeNotifier {
  final SensorSimulator _simulator = SensorSimulator();

  // Valores actuales de los sensores
  List<double> _sensorValues = List.filled(11, 0.0);

  // Getters — aquí decides qué índice es cada sensor
  double get cervicalAngle => _sensorValues[0];
  double get toracicAngle  => _sensorValues[1];
  double get lumbarAngle   => _sensorValues[2];
  double get minutsAssegut => _sensorValues[10];

  // Lógica de postura correcta
  bool get cervicalOk => cervicalAngle <= 10;
  bool get toracicOk  => toracicAngle  <= 15;
  bool get lumbarOk   => lumbarAngle   <= 10;

  // Porcentaje de buena postura (0.0 a 1.0)
  double get bonPostura {
    int correctes = 0;
    if (cervicalOk) correctes++;
    if (toracicOk)  correctes++;
    if (lumbarOk)   correctes++;
    return correctes / 3;
  }

  // Tiempo sentado formateado
  String get tempsAssegut {
    int hores  = minutsAssegut.toInt() ~/ 60;
    int minuts = minutsAssegut.toInt() % 60;
    return hores > 0 ? '${hores}h ${minuts}m' : '${minuts}m';
  }

  void start() {
    _simulator.start();
    _simulator.stream.listen((values) {
      _sensorValues = values;
      notifyListeners(); // avisa a los widgets que hay datos nuevos
    });
  }

  void stop() {
    _simulator.stop();
  }
}