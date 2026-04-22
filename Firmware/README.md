# Firmware de Adquisición de Datos (ESP32)

Este firmware está diseñado para el cojín y respaldo inteligente detector de postura. Lee los datos de 12 sensores de presión (FSR) y 3 sensores de ultrasonido (HC-SR04), los procesa y los envía a través de Bluetooth y el puerto Serial en formato JSON.

## 1. Conexiones y Pines

- **Sensores Ultrasónicos (HC-SR04):**
  - Se utilizan 3 sensores ubicados en las zonas: Cervical, Torácica y Lumbar.
  - Pines `Trig` (salida): 7, 7, 7 (comparten pin).
  - Pines `Echo` (entrada): 2, 3, 6.
- **Multiplexor (CD74HC4067):**
  - Lee los 12 sensores FSR (tanto del asiento como del respaldo).
  - Pin analógico común (salida del mux): 32.
  - Pines selectores (S0-S3): 18, 19, 21, 22.

## 2. Configuración (`setup()`)
- Se inicializan las comunicaciones Serial a 115200 baudios y Bluetooth Clásico con el nombre `"Cadira_Postural"`.
- Se configuran los pines de los ultrasonidos (Trig como salida, Echo como entrada) y los selectores del multiplexor (salidas).

## 3. Bucle Principal (`loop()`)

El bucle principal sigue la siguiente lógica iterativa:

### 3.1. Lectura de Presencia (FSRs)
Se leen los 12 canales del multiplexor conectando cíclicamente los selectores. Se asume que el asiento está **ocupado** si **cualquiera** de los sensores FSR de presión registra un valor superior a `500` (sobre 4095 del conversor analógico de la ESP32).

### 3.2. Silla Vacía
Si la silla no está ocupada:
- Envía un JSON indicando estado vacío: `{"estat":"buida"}`.
- Espera 10 segundos antes de la siguiente revisión para ahorrar energía y procesamiento (modo reposo).

### 3.3. Silla Ocupada (Fusión Sensorial)
Si la silla está ocupada, entra al modo activo (mediciones cada 500 ms):
1. **Ultrasonidos:** Envía pulsos por los pines `Trig` y mide el tiempo de respuesta en `Echo` usando un *timeout* de 6000 microsegundos (~100 cm máximo).
2. **Fusión Sensorial FSR + Ultrasonido:** 
   - Se comprueban los 2 sensores FSR correspondientes a la misma zona de la espalda de cada ultrasonido.
   - Si los FSR indican contacto (valores > 400), se considera que la persona está rozando el respaldo.
   - **Corrección de errores:** Si el sensor de ultrasonido falla (devuelve 0 cm, menos de 2 cm o más de 100 cm):
     - Si la persona **está tocando el respaldo** (FSR activados): se asume la distancia de ceguera del sensor (`2.0` cm).
     - Si la persona **no está tocando el respaldo**: se asume que está fuera de rango (`100.0` cm).

### 3.4. Envío de Datos (JSON)
Si la silla está ocupada, recopila todos los datos en un formato JSON estructurado con claves específicas y lo envía tanto por consola Serial como por Bluetooth (SerialBT). 

Se envían los 6 FSR del asiento, los 6 FSR del respaldo y las 3 distancias depuradas de los ultrasonidos. Ejemplo:
```json
{"fsrCulDavantEsq":0,"fsrCulDavantDret":0,...,"fsrEsquenaBaixDret":980,"usCervical":2.0,"usToracic":14.5,"usLumbar":100.0}
```
