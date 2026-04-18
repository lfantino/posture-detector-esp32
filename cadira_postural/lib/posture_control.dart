import 'dart:async';
import 'package:flutter/material.dart';
import 'sensor_simulator.dart';

// ─── THRESHOLDS (canvia aquests valors quan tingueu dades reals) ──────────────

const double kMaxDiferenciaLateral  = 20.0; // diferència màx esquerra vs dreta
const double kMaxDiferenciaFrontal  = 25.0; // diferència màx davant vs darrere
const double kMaxDiferenciaVertical = 25.0; // diferència màx alt vs baix (esquena)
const double kMinPresioDeteccio     = 10.0; // pressió mínima per detectar presència
const double kMaxAngleCervical      = 15.0; // angle màx cervical en cm (ultrasò)
const double kMaxAngleToracic       = 20.0; // angle màx toràcic en cm (ultrasò)
const double kMaxAngleLumbar        = 15.0; // angle màx lumbar en cm (ultrasò)

// ─── POSTURE CONTROLLER ───────────────────────────────────────────────────────

class PostureController extends ChangeNotifier {
  final SensorSimulator _simulator = SensorSimulator();

  List<double> _sensorValues = List.filled(15, 0.0);

  Duration _tempsAssegut = Duration.zero;
  DateTime? _iniciSessio;
  Timer? _timerTemps;

  // ── Getters cojín culo (FSR 0-5) ─────────────────────────────────────────

  double get fsrCulDavantEsq     => _sensorValues[0];
  double get fsrCulDavantCentre  => _sensorValues[1];
  double get fsrCulDavantDret    => _sensorValues[2];
  double get fsrCulDarrereEsq    => _sensorValues[3];
  double get fsrCulDarrereCentre => _sensorValues[4];
  double get fsrCulDarrereDret   => _sensorValues[5];

  // ── Getters cojín espalda (FSR 6-11) ─────────────────────────────────────

  double get fsrEsquenaAltEsq     => _sensorValues[6];
  double get fsrEsquenaAltCentre  => _sensorValues[7];
  double get fsrEsquenaAltDret    => _sensorValues[8];
  double get fsrEsquenaBaixEsq    => _sensorValues[9];
  double get fsrEsquenaBaixCentre => _sensorValues[10];
  double get fsrEsquenaBaixDret   => _sensorValues[11];

  // ── Getters ultrasonidos (12-14) ──────────────────────────────────────────

  double get usCervical => _sensorValues[12];
  double get usToracic  => _sensorValues[13];
  double get usLumbar   => _sensorValues[14];

  // ── Detecció de presència ─────────────────────────────────────────────────
  // Considera que algú seu si almenys un FSR del cul supera el mínim

  bool get hiHaAlgu =>
      fsrCulDavantEsq     > kMinPresioDeteccio ||
      fsrCulDavantCentre  > kMinPresioDeteccio ||
      fsrCulDavantDret    > kMinPresioDeteccio ||
      fsrCulDarrereEsq    > kMinPresioDeteccio ||
      fsrCulDarrereCentre > kMinPresioDeteccio ||
      fsrCulDarrereDret   > kMinPresioDeteccio;

  // ── Anàlisi cojín culo ────────────────────────────────────────────────────

  // Simetria lateral: promedio esquerra vs dreta
  double get _pressioCulEsq    => (fsrCulDavantEsq  + fsrCulDarrereEsq)  / 2;
  double get _pressioCulDret   => (fsrCulDavantDret + fsrCulDarrereDret) / 2;
  double get diferenciaCulLateral => (_pressioCulEsq - _pressioCulDret).abs();
  bool get culLateralOk => diferenciaCulLateral <= kMaxDiferenciaLateral;

  // Simetria frontal: promedio davant vs darrere
  double get _pressioCulDavant  => (fsrCulDavantEsq  + fsrCulDavantCentre  + fsrCulDavantDret)  / 3;
  double get _pressioCulDarrere => (fsrCulDarrereEsq + fsrCulDarrereCentre + fsrCulDarrereDret) / 3;
  double get diferenciaCulFrontal => (_pressioCulDavant - _pressioCulDarrere).abs();
  bool get culFrontalOk => diferenciaCulFrontal <= kMaxDiferenciaFrontal;

  // ── Anàlisi cojín espalda ─────────────────────────────────────────────────

  // Simetria lateral: promedio esquerra vs dreta
  double get _pressioEsquenaEsq  => (fsrEsquenaAltEsq  + fsrEsquenaBaixEsq)  / 2;
  double get _pressioEsquenaDret => (fsrEsquenaAltDret + fsrEsquenaBaixDret) / 2;
  double get diferenciaEsquenaLateral => (_pressioEsquenaEsq - _pressioEsquenaDret).abs();
  bool get esquenaLateralOk => diferenciaEsquenaLateral <= kMaxDiferenciaLateral;

  // Simetria vertical: promedio alt vs baix
  double get _pressioEsquenaAlt  => (fsrEsquenaAltEsq  + fsrEsquenaAltCentre  + fsrEsquenaAltDret)  / 3;
  double get _pressioEsquenaBaix => (fsrEsquenaBaixEsq + fsrEsquenaBaixCentre + fsrEsquenaBaixDret) / 3;
  double get diferenciaEsquenaVertical => (_pressioEsquenaAlt - _pressioEsquenaBaix).abs();
  bool get esquenaVerticalOk => diferenciaEsquenaVertical <= kMaxDiferenciaVertical;

  // ── Anàlisi ultrasonidos ──────────────────────────────────────────────────
  // Els ultrasonidos mesuren distància en cm
  // Si la distància és molt gran, la persona s'ha allunyat del respatller

  bool get cervicalOk => usCervical <= kMaxAngleCervical;
  bool get toracicOk  => usToracic  <= kMaxAngleToracic;
  bool get lumbarOk   => usLumbar   <= kMaxAngleLumbar;

  // ── Postura global ────────────────────────────────────────────────────────
  // Combina els 7 criteris: 2 del cul, 2 de