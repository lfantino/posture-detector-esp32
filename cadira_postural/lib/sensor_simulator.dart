import 'dart:async';
import 'dart:math';

class SensorSimulator {
  final Random _random = Random();
  StreamController<List<double>>? _controller;
  Timer? _timer;

  Stream<List<double>> get stream => _controller!.stream;

  void start() {
    _controller = StreamController<List<double>>.broadcast();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _controller!.add(_generateList());
    });
  }

  void stop() {
    _timer?.cancel();
    _controller?.close();
  }

  List<double> _generateList() {
    return List.generate(9, (_) => _random.nextDouble() * 100);
  }
}