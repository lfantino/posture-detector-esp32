// Abrir en Arduino IDE 


#include <Arduino.h>
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

// Pines
const int trigPins[] = {13, 14, 26}; // pines trigger de sensor 0, 1 y 2, cambiar a los que sean correctos
const int echoPins[] = {12, 27, 25}; // pines echo de sensor 0, 1 y 2, cambiar a los que sean correctos

void setup() {
  // En Arduino IDE el Serial Monitor debe estar a 115200
  Serial.begin(115200);
  
  // Nombre para el móvil
  SerialBT.begin("ESP32_Postura_IDE"); 

  for(int i = 0; i < 3; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }
  
  Serial.println("Sistema listo. Abre el Serial Plotter para ver las graficas.");
}

void loop() {
  // 1. Lectura de los 3 sensores
  for(int i = 0; i < 3; i++) {
    digitalWrite(trigPins[i], LOW);
    delayMicroseconds(2);
    digitalWrite(trigPins[i], HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPins[i], LOW);

    long duration = pulseIn(echoPins[i], HIGH, 30000);
    float distance = duration * 0.034 / 2;

    if (distance <= 0 || distance > 400) distance = 0;

    // 2. SALIDA PARA DEBUG (Arduino IDE)
    // Formato: "Etiqueta:Valor" para que el Serial Plotter lo reconozca
    if (i == 0) Serial.print("Cervical:");
    if (i == 1) Serial.print("Dorsal:");
    if (i == 2) Serial.print("Lumbar:");
    
    Serial.print(distance);
    
    // 3. ENVÍO BLUETOOTH (Para el móvil)
    SerialBT.print(distance);

    // Formateo de comas y espacios
    if (i < 2) {
      Serial.print(" ");   // Espacio para el Serial Plotter
      SerialBT.print(","); // Coma para la App del móvil
    }
  }

  Serial.println();   // Salto de línea para el PC
  SerialBT.println(); // Salto de línea para el Móvil
  
  delay(200); // Un poco más rápido para que la gráfica sea fluida
}