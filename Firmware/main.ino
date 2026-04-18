// Pines Ultrasonidos
const int trigPins[] = {23, 23, 23};
const int echoPins[] = {16, 17, 33};
const char *usLabels[] = {"Cervical", "Dorsal", "Lumbar"};

// Pines Multiplexor
const int muxCom = 32;
const int sPins[] = {18, 19, 21, 22}; // S0=32, S1=33, S2=18, S3=19

void setup() {
  Serial.begin(115200);

  // Setup Ultrasonidos
  for (int i = 0; i < 3; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }

  // Setup MUX
  for (int i = 0; i < 4; i++) {
    pinMode(sPins[i], OUTPUT);
  }

  Serial.println("--- SISTEMA DE POSTURA COMPLETO ---");
}

void loop() {
  bool ocupado = false;
  int lecturasFSR[12];

  // 1. Leer los 12 FSR vía MUX primero para decidir el sampling
  for (int i = 0; i < 12; i++) {
    for (int j = 0; j < 4; j++) {
      digitalWrite(sPins[j], (i >> j) & 0x01);
    }
    delay(2);
    lecturasFSR[i] = analogRead(muxCom);
    // Si algún sensor del asiento (canales 6-11) supera un umbral, está ocupado
    if (i >= 6 && lecturasFSR[i] > 500)
      ocupado = true;
  }

  // 2. Si está ocupado, leemos ultrasonidos y enviamos todo
  if (ocupado) {
    for (int i = 0; i < 3; i++) {
      digitalWrite(trigPins[i], LOW);
      delayMicroseconds(2); // Limpia pin
      digitalWrite(trigPins[i], HIGH);
      delayMicroseconds(10);          // Manda pulso de activación
      digitalWrite(trigPins[i], LOW); // Corta pulso
      long duration =
          pulseIn(echoPins[i], HIGH); // Mide cuánto tiempo tarda en llegar el
                                      // sonido y activar el echoPin
      float distancia = duration * 0.034 / 2;
      Serial.print(distancia);
      Serial.print(",");
    }
    for (int i = 0; i < 12; i++) {
      Serial.print(lecturasFSR[i]);
      if (i < 11)
        Serial.print(",");
    }
    Serial.println();
    delay(500); // Sampling rápido (Modo Activo)
  } else {
    Serial.println("Silla vacía - Modo Ahorro");
    delay(10000); // Sampling lento (Modo Reposo)
  }
}
