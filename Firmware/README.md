# Firmware de Adquisición de Datos (ESP32) — v2

Este firmware está diseñado para el cojín y respaldo inteligente detector de postura. Lee los datos de **6 sensores de presión (FSR)** ubicados en el asiento y **3 sensores ultrasónicos (HC-SR04)** ubicados en el respaldo, los procesa y los envía a través de Bluetooth y el puerto Serial en formato JSON.

## 1. Arquitectura de Sensores

| Zona | Sensor | Cantidad | Propósito |
|---|---|---|---|
| **Asiento** | FSR (Force Sensitive Resistor) | 6 | Detectar presencia y distribución del peso |
| **Respaldo** | HC-SR04 (Ultrasonido) | 3 | Medir la distancia a la espalda (Cervical, Torácico, Lumbar) |

> **Cambio respecto a v1:** El respaldo ya **no** lleva sensores de presión FSR. La zona dorsal se monitoriza exclusivamente mediante ultrasonidos.

---

## 2. Conexiones y Pines

### Sensores Ultrasónicos HC-SR04 (respaldo)
- **Pin `Trig`** (salida, compartido): **7**
- **Pines `Echo`** (entradas individuales): **2** (Cervical) · **3** (Torácico) · **6** (Lumbar)

### Multiplexor CD74HC4067 (asiento — canales 0–5)
- **Pin analógico común** (lectura ADC): **32**
- **Pines selectores S0–S3**: **18, 19, 21, 22**

### Mapeo de canales MUX → FSR del asiento

| Canal MUX | Clave JSON | Posición |
|---|---|---|
| 0 | `fsrDavantEsq` | Delante Izquierdo |
| 1 | `fsrDavantDret` | Delante Derecho |
| 2 | `fsrMigEsq` | Centro Izquierdo |
| 3 | `fsrMigDret` | Centro Derecho |
| 4 | `fsrDarrereEsq` | Detrás Izquierdo |
| 5 | `fsrDarrereDret` | Detrás Derecho |

---

## 3. Configuración (`setup()`)

- Comunicación Serial a **115200 baudios**.
- Bluetooth Clásico (SSP) con el nombre `"Cadira_Postural"`.
- Pin `Trig` compartido como salida; pines `Echo` como entradas.
- Pines selectores del MUX como salidas.

---

## 4. Bucle Principal (`loop()`)

### 4.1. Detección de Presencia (FSRs del asiento)
Se leen los **6 canales** del multiplexor secuencialmente. Si cualquier FSR supera el umbral de `500` (sobre 4095), el sistema considera el asiento como **ocupado**.

### 4.2. Estado Vacío (Modo Reposo)
Si el asiento no está ocupado:
- Envía el JSON: `{"estat":"buida"}`
- Espera **10 segundos** antes de la siguiente comprobación (ahorro de energía).

### 4.3. Estado Ocupado (Modo Activo — ~2 Hz)
Si el asiento está ocupado, realiza las siguientes operaciones cada 500 ms:

#### Lectura de Ultrasonidos
Dispara el pulso Trig (compartido) para cada sensor y mide el tiempo de echo individual. El timeout es de **6000 µs**, equivalente a ~100 cm de alcance máximo.

#### Validación de Lecturas Ultrasónicas
Sin FSR en el respaldo, la validación es puramente basada en el tiempo de vuelo:

| Condición | Valor asignado | Interpretación |
|---|---|---|
| `duration == 0` (timeout) | `100.0 cm` | Eco no regresó → persona no apoyada |
| `calcDist < 2.0 cm` | `2.0 cm` | Zona ciega del sensor → contacto total |
| `calcDist > 100.0 cm` | `100.0 cm` | Fuera de rango clínico |
| `2.0 ≤ calcDist ≤ 100.0` | Valor medido | Lectura válida |

> **Nota técnica:** En v1, los FSR del respaldo permitían distinguir si un timeout del ultrasonido se debía a ceguera por proximidad o a dispersión por lejanía. En v2, ante un timeout se asume conservadoramente que la persona **no está apoyada** (100 cm). Si el sensor devuelve una distancia en su zona ciega (< 2 cm), se asume contacto total.

---

## 5. Formato de Salida JSON

### Silla vacía
```json
{"estat":"buida"}
```

### Silla ocupada
```json
{
  "fsrDavantEsq":  1024,
  "fsrDavantDret": 980,
  "fsrMigEsq":     1100,
  "fsrMigDret":    870,
  "fsrDarrereEsq": 0,
  "fsrDarrereDret":0,
  "usCervical":    14.5,
  "usToracic":     22.0,
  "usLumbar":      100.0
}
```

Los datos se envían simultáneamente por:
- **Puerto Serie USB** (115200 baudios) — para depuración con Arduino IDE.
- **Bluetooth Serial (SerialBT)** — para la app móvil `Cadira_Postural`.

---

## 6. Instalación y Flasheo

1. Abre `main_v2.ino` en **Arduino IDE** o **PlatformIO**.
2. Instala el core oficial del **ESP32** desde el Gestor de Tarjetas si no lo tienes.
3. Instala la librería **BluetoothSerial** (incluida en el core ESP32).
4. Selecciona la placa y el puerto COM correctos.
5. Compila y sube. Verifica el output en el Monitor Serie a **115200 baudios**.
