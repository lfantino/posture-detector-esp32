#nova versió
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
    if (i >= 6 && lecturasFSR[i] > 500)
      ocupado = true;
  }

  if (ocupado) {
    float distancias[3];

    // 2. Leer ultrasonidos
    for (int i = 0; i < 3; i++) {
      digitalWrite(trigPins[i], LOW);
      delayMicroseconds(2);
      digitalWrite(trigPins[i], HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPins[i], LOW);
      long duration = pulseIn(echoPins[i], HIGH);
      distancias[i] = duration * 0.034 / 2;
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
