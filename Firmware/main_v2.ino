#include "BluetoothSerial.h"
BluetoothSerial SerialBT;

// -----------------------------------------------------------------------
// PINES — SENSORES ULTRASÓNICOS (respaldo)
// Tres sensores HC-SR04 ubicados en las zonas: Cervical, Torácico, Lumbar.
// Comparten el mismo pin Trig para reducir el uso de pines GPIO.
// -----------------------------------------------------------------------
const int trigPin = 7;            // Pin Trig compartido por los 3 ultrasonidos
const int echoPins[] = {2, 3, 6}; // Echo: Cervical | Torácico | Lumbar

// -----------------------------------------------------------------------
// PINES — MULTIPLEXOR (asiento)
// El multiplexor CD74HC4067 lee los 6 sensores FSR del asiento.
// Solo se usan los canales 0–5 del MUX.
// -----------------------------------------------------------------------
const int muxCom = 32;                // Salida analógica del MUX → ESP32
const int sPins[] = {18, 19, 21, 22}; // Selectores S0–S3 del MUX

// -----------------------------------------------------------------------
// CONSTANTES DE CONFIGURACIÓN
// -----------------------------------------------------------------------
const int NUM_FSR = 6; // Número de sensores FSR en el asiento
const int NUM_US = 3;  // Número de sensores ultrasónicos en el respaldo
const int UMBRAL_FSR =
    500; // Valor mínimo (0–4095) para considerar asiento ocupado
const int US_TIMEOUT_US =
    6000; // Timeout pulseIn en µs (~100 cm de alcance máximo)
const float DIST_MIN_CM =
    2.0; // Distancia mínima fiable del HC-SR04 (zona ciega)
const float DIST_MAX_CM = 100.0; // Distancia máxima considerada válida

void setup() {
  Serial.begin(115200);
  SerialBT.begin("Cadira_Postural");

  // Configurar pin Trig compartido como salida
  pinMode(trigPin, OUTPUT);

  // Configurar pines Echo como entradas
  for (int i = 0; i < NUM_US; i++) {
    pinMode(echoPins[i], INPUT);
  }

  // Configurar pines selectores del MUX como salidas
  for (int i = 0; i < 4; i++) {
    pinMode(sPins[i], OUTPUT);
  }

  Serial.println("--- SISTEMA DE POSTURA v2 ---");
  Serial.println("Asiento: 6 FSR via MUX | Respaldo: 3 Ultrasonidos");
}

void loop() {
  bool ocupado = false;
  int lecturasFSR[NUM_FSR];

  // -----------------------------------------------------------------------
  // PASO 1: Leer los 6 FSR del asiento via multiplexor
  // El asiento se considera OCUPADO si cualquier FSR supera el umbral.
  // -----------------------------------------------------------------------
  for (int i = 0; i < NUM_FSR; i++) {
    // Seleccionar canal i en el MUX poniendo los 4 bits del selector
    for (int j = 0; j < 4; j++) {
      digitalWrite(sPins[j], (i >> j) & 0x01);
    }
    delay(2); // Pequeña espera para que el MUX estabilice la señal
    lecturasFSR[i] = analogRead(muxCom);

    if (lecturasFSR[i] > UMBRAL_FSR) {
      ocupado = true;
    }
  }

  // -----------------------------------------------------------------------
  // PASO 2: Según el estado de ocupación, actuar
  // -----------------------------------------------------------------------
  if (!ocupado) {
    // Silla vacía: enviar estado de reposo y esperar 10 s
    String json = "{\"estat\":\"buida\"}";
    Serial.println(json);
    SerialBT.println(json);
    delay(10000);

  } else {
    // Silla ocupada: leer ultrasonidos del respaldo
    float distancias[NUM_US];

    for (int i = 0; i < NUM_US; i++) {
      // Generar pulso de disparo (Trig compartido)
      digitalWrite(trigPin, LOW);
      delayMicroseconds(2);
      digitalWrite(trigPin, HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPin, LOW);

      // Medir el tiempo de vuelo del eco con timeout
      long duration = pulseIn(echoPins[i], HIGH, US_TIMEOUT_US);
      float calcDist = duration * 0.034 / 2.0;

      // -------------------------------------------------------------------
      // VALIDACIÓN Y CORRECCIÓN DE LECTURAS ULTRASÓNICAS
      //
      // Sin FSR en el respaldo, no podemos distinguir si un fallo se debe
      // a que el sensor está cegado (persona muy cerca) o a que la onda
      // se dispersó (persona alejada). Se aplican las siguientes reglas:
      //
      //  · duration == 0 (timeout):
      //      El eco no regresó dentro del rango de 100 cm.
      //      Asumimos que la persona NO está apoyada → 100.0 cm.
      //
      //  · calcDist < DIST_MIN_CM (zona ciega del sensor):
      //      La persona está rozando físicamente el respaldo.
      //      Se fija al mínimo fiable → 2.0 cm.
      //
      //  · calcDist > DIST_MAX_CM:
      //      Fuera del rango de interés clínico.
      //      Se fija al máximo → 100.0 cm.
      //
      //  · Lectura válida (2.0–100.0 cm): se usa directamente.
      // -------------------------------------------------------------------
      if (duration == 0) {
        distancias[i] = DIST_MAX_CM; // Timeout → asumimos sin contacto
      } else if (calcDist < DIST_MIN_CM) {
        distancias[i] = DIST_MIN_CM; // Zona ciega → contacto total
      } else if (calcDist > DIST_MAX_CM) {
        distancias[i] = DIST_MAX_CM; // Fuera de rango → sin contacto
      } else {
        distancias[i] = calcDist; // Lectura válida
      }

      delay(30); // Espera entre disparos para evitar interferencias entre
                 // sensores
    }

    // -----------------------------------------------------------------------
    // PASO 3: Construir y enviar el JSON
    //
    // Claves FSR (asiento):
    //   Canal 0 → fsrDavantEsq   (Delante Izquierdo)
    //   Canal 1 → fsrDavantDret  (Delante Derecho)
    //   Canal 2 → fsrMigEsq      (Centro Izquierdo)
    //   Canal 3 → fsrMigDret     (Centro Derecho)
    //   Canal 4 → fsrDarrereEsq  (Detrás Izquierdo)
    //   Canal 5 → fsrDarrereDret (Detrás Derecho)
    //
    // Claves Ultrasonido (respaldo):
    //   usCervical | usToracic | usLumbar
    // -----------------------------------------------------------------------
    String json = "{";

    // FSR asiento (canales 0–5)
    json += "\"fsrDavantEsq\":" + String(lecturasFSR[0]) + ",";
    json += "\"fsrDavantDret\":" + String(lecturasFSR[1]) + ",";
    json += "\"fsrMigEsq\":" + String(lecturasFSR[2]) + ",";
    json += "\"fsrMigDret\":" + String(lecturasFSR[3]) + ",";
    json += "\"fsrDarrereEsq\":" + String(lecturasFSR[4]) + ",";
    json += "\"fsrDarrereDret\":" + String(lecturasFSR[5]) + ",";

    // Ultrasonidos respaldo
    json += "\"usCervical\":" + String(distancias[0], 1) + ",";
    json += "\"usToracic\":" + String(distancias[1], 1) + ",";
    json += "\"usLumbar\":" + String(distancias[2], 1);

    json += "}";

    Serial.println(json);
    SerialBT.println(json);

    delay(500); // Frecuencia de muestreo: ~2 Hz en modo activo
  }
}
