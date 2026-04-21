#include "BluetoothSerial.h"
BluetoothSerial SerialBT;

// Pines Ultrasonidos (definitivos)
const int trigPins[] = {7, 7, 7};
const int echoPins[] = {2, 3, 6};

// Pines Multiplexor (no definitivos)
const int muxCom = 32;
const int sPins[] = {18, 19, 21, 22};

void setup() {
  Serial.begin(115200);
  SerialBT.begin("Cadira_Postural");

  for (int i = 0; i < 3; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }
  for (int i = 0; i < 4; i++) {
    pinMode(sPins[i], OUTPUT);
  }

  Serial.println("--- SISTEMA DE POSTURA COMPLETO ---");
}

void loop() {
  bool ocupado = false;
  int lecturasFSR[12];

  // 1. Leer los 12 FSR vía MUX
  for (int i = 0; i < 12; i++) {
    for (int j = 0; j < 4; j++) {
      digitalWrite(sPins[j], (i >> j) & 0x01);
    }
    delay(2);
    lecturasFSR[i] = analogRead(muxCom);

    // Si *CUALQUIER* sensor de presión del cojín detecta peso, está ocupado.
    // Usamos esto para evitar el bug si cambian el mapeo de cables en el
    // futuro.
    if (lecturasFSR[i] > 500) {
      ocupado = true;
    }
  }

  if (ocupado) {
    float distancias[3];

    // 2. Leer ultrasonidos con Fusión Sensorial
    for (int i = 0; i < 3; i++) {
      digitalWrite(trigPins[i], LOW);
      delayMicroseconds(2);
      digitalWrite(trigPins[i], HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPins[i], LOW);

      // TIMEOUT de 6000us (6ms). Equivale a esperar un rebote a un máximo de ~100 cm.
      // Si el sonido no vuelve en ese tiempo, la función se corta rápido y devuelve 0.
      long duration = pulseIn(echoPins[i], HIGH, 6000);
      float calcDist = duration * 0.034 / 2;

      // Evaluamos qué dicen los FSR de esa misma zona para discernir
      // i=0 (Cervical) -> FSRs 6 y 7
      // i=1 (Torácico) -> FSRs 8 y 9
      // i=2 (Lumbar)   -> FSRs 10 y 11
      int fsrIzquierdo = lecturasFSR[6 + (i * 2)];
      int fsrDerecho = lecturasFSR[7 + (i * 2)];

      // Umbral para considerar que la persona está presionando físicamente el
      // respaldo Ajustable empíricamente (suele ser un poco menor que el del
      // propio asiento porque la espalda ejerce menos peso)
      bool tocandoRespaldo = (fsrIzquierdo > 400 || fsrDerecho > 400);

      // Si el HC-SR04 falla dándonos un cero o valores imposibles (<2cm o >100cm)
      // tomamos acciones preventivas
      if (duration == 0 || calcDist < 2.0 || calcDist > 100.0) {
        if (tocandoRespaldo) {
          // Error por "ceguera" del sensor al estar tapado: Asumimos que está
          // totalmente pegado.
          distancias[i] = 2.0;
        } else {
          // Error por estar la onda demasiado dispersa/lejana: Asumimos que
          // está inclinado lejos del respaldo. (Límite máximo 1 metro).
          distancias[i] = 100.0;
        }
      } else {
        // Medición válida y limpia. Nos fiamos totalmente del ultrasonido.
        distancias[i] = calcDist;
      }
    }

    // 3. Construir JSON con los nombres exactos de los getters
    String json = "{";

    // FSR Cojín asiento (canales 0–5)
    json += "\"fsrCulDavantEsq\":" + String(lecturasFSR[0]) + ",";
    json += "\"fsrCulDavantDret\":" + String(lecturasFSR[1]) + ",";
    json += "\"fsrCulMigEsq\":" + String(lecturasFSR[2]) + ",";
    json += "\"fsrCulMigDret\":" + String(lecturasFSR[3]) + ",";
    json += "\"fsrCulDarrereEsq\":" + String(lecturasFSR[4]) + ",";
    json += "\"fsrCulDarrereDret\":" + String(lecturasFSR[5]) + ",";

    // FSR Cojín espalda (canales 6–11)
    json += "\"fsrEsquenaAltEsq\":" + String(lecturasFSR[6]) + ",";
    json += "\"fsrEsquenaAltDret\":" + String(lecturasFSR[7]) + ",";
    json += "\"fsrEsquenaMigEsq\":" + String(lecturasFSR[8]) + ",";
    json += "\"fsrEsquenaMigDret\":" + String(lecturasFSR[9]) + ",";
    json += "\"fsrEsquenaBaixEsq\":" + String(lecturasFSR[10]) + ",";
    json += "\"fsrEsquenaBaixDret\":" + String(lecturasFSR[11]) + ",";

    // Ultrasonidos (índices 12–14)
    json += "\"usCervical\":" + String(distancias[0], 1) + ",";
    json += "\"usToracic\":" + String(distancias[1], 1) + ",";
    json += "\"usLumbar\":" + String(distancias[2], 1);

    json += "}";

    Serial.println(json);
    SerialBT.println(json);

    delay(500);

  } else {
    String json = "{\"estat\":\"buida\"}";
    Serial.println(json);
    SerialBT.println(json);
    delay(10000);
  }
}
