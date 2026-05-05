# Firmware d'Adquisició de Dades (ESP32-C5) — v2

Aquest firmware s'executa sobre un **ESP32-C5 DevKit** i gestiona el cojí intel·ligent detector de postura. Llegeix **6 sensors de pressió FSR** al seient i **3 sensors ultrasònics HC-SR04** al respatller, processa les dades i les envia per **Bluetooth Low Energy (BLE)** a l'aplicació mòbil.

---

## 1. Arquitectura de Sensors

| Zona | Sensor | Quantitat | Propòsit |
|---|---|---|---|
| **Seient** | FSR (Force Sensitive Resistor) | 6 | Detectar presència i distribució del pes |
| **Respatller** | HC-SR04 (Ultrasònic) | 3 | Mesurar la distància a l'esquena (Cervical, Toràcic, Lumbar) |

> **Canvi respecte a v1:** El respatller ja **no** porta sensors de pressió FSR. La zona dorsal es monitoritza exclusivament mitjançant ultrasonidos.

---

## 2. Connexions i Pins (ESP32-C5)

### Sensors Ultrasònics HC-SR04 (respatller)
- **Pin `Trig`** (sortida, compartit pels 3): GPIO **7**
- **Pins `Echo`** (entrades individuals): GPIO **2** (Cervical) · **3** (Toràcic) · **6** (Lumbar)

### Multiplexor CD74HC4067 (seient — canals 0–5)
- **Pin analògic comú** (lectura ADC): GPIO **4**
- **Pins selectores S0–S3**: GPIO **10, 5, 8, 28**

### LED RGB WS2812B (keep-alive powerbank)
- GPIO **27**

### Mapatge de canals MUX → FSR del seient

| Canal MUX | Clau JSON | Posició |
|---|---|---|
| 0 | `fsrDavantEsq` | Davant Esquerre |
| 1 | `fsrDavantDret` | Davant Dret |
| 2 | `fsrMigEsq` | Mig Esquerre |
| 3 | `fsrMigDret` | Mig Dret |
| 4 | `fsrDarrereEsq` | Darrere Esquerre |
| 5 | `fsrDarrereDret` | Darrere Dret |

---

## 3. Protocol de Comunicació: BLE NUS

> L'**ESP32-C5 no suporta Bluetooth Classic** (BR/EDR). El firmware usa **Bluetooth Low Energy (BLE)** amb el **Nordic UART Service (NUS)**, l'estàndard obert per emular una UART sobre BLE.

| UUID | Rol |
|---|---|
| `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | Servei NUS |
| `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | TX Characteristic — ESP32 → App (Notify) |
| `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | RX Characteristic — App → ESP32 (Write) |

El JSON s'envia fragmentat en chunks de **20 bytes** (MTU base de BLE) amb un `\n` al final de l'últim fragment. L'app acumula els fragments fins al `\n` per reassemblar el missatge complet.

---

## 4. Configuració (`setup()`)

- Comunicació Serial a **115200 baudios** (per a debug amb Arduino IDE).
- Inicialització BLE amb nom `"Cadira_Postural"` i advertisi actiu.
- Pin `Trig` compartit com a sortida; pins `Echo` com a entrades.
- Pins selectores del MUX com a sortides.
- LED RGB WS2812B inicialitzat en blanc (keep-alive de la powerbank).

---

## 5. Bucle Principal (`loop()`)

### 5.1. Keep-alive de la Powerbank
El LED RGB es manté **sempre encès en blanc** (brillo 80/255, ~20 mA). Les powerbanks s'apaguen automàticament si el consum cau per sota de ~50–100 mA; el LED garanteix un consum mínim sostingut.

### 5.2. Detecció de Presència (FSR del seient)
Es llegeixen els **6 canals** del multiplexor seqüencialment. Si qualsevol FSR supera el llindar de `500` (sobre 4095), el sistema considera el seient com a **ocupat**.

### 5.3. Estat Buit (Mode Repòs)
Si el seient no està ocupat:
- Envia el JSON: `{"estat":"buida"}`
- Espera **3 segons** abans de la següent comprovació.

> El interval és de 3 s (i no 10 s) per mantenir el ràdio BLE actiu prou sovint i evitar que la powerbank detecti consum insuficient.

### 5.4. Estat Ocupat (Mode Actiu — ~2 Hz)
Si el seient està ocupat, llegeix els 3 ultrasònics i envia el JSON complet cada **500 ms**.

#### Lectura d'Ultrasònics
Dispara el puls Trig (compartit) per a cada sensor i mesura el temps d'eco individual. El timeout és de **6000 µs**, equivalent a ~100 cm d'abast màxim.

#### Validació de Lectures Ultrasòniques

| Condició | Valor assignat | Interpretació |
|---|---|---|
| `duration == 0` (timeout) | `100.0 cm` | Eco no va tornar → persona no recolzada |
| `calcDist < 2.0 cm` | `2.0 cm` | Zona cega del sensor → contacte total |
| `calcDist > 100.0 cm` | `100.0 cm` | Fora de rang clínic |
| `2.0 ≤ calcDist ≤ 100.0` | Valor mesurat | Lectura vàlida |

---

## 6. Format de Sortida JSON

### Cadira buida
```json
{"estat":"buida"}
```

### Cadira ocupada
```json
{
  "fsrDavantEsq":  312,  "fsrDavantDret": 287,
  "fsrMigEsq":     301,  "fsrMigDret":    290,
  "fsrDarrereEsq": 278,  "fsrDarrereDret":265,
  "usCervical":   14.2,  "usToracic":    18.5,  "usLumbar": 12.1
}
```

Les dades s'envien simultàniament per:
- **Port Sèrie USB** (115200 baud) — per a depuració amb Arduino IDE.
- **BLE (NUS TX Notify)** — per a l'app mòbil `Cadira_Postural`.

---

## 7. Instal·lació i Flasheig

### Requisits previs
1. **Arduino IDE 2.x** → [arduino.cc/en/software](https://www.arduino.cc/en/software)
2. Core **ESP32 ≥ 3.0.0** — afegir URL al Gestor de Plaques:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Llibreria **Adafruit NeoPixel** → instal·lar des del Gestor de Biblioteques

### Passos
1. Selecciona la placa: **ESP32C5 Dev Module**
2. Selecciona el port USB correcte
3. Obre `main_v2.ino`, compila (`Ctrl+R`) i flasheja (`Ctrl+U`)
4. Si el upload falla, mantén el botó **BOOT** premut mentre comença l'upload
5. Verifica al **Monitor Sèrie** (115200 baud):

```
--- SISTEMA DE POSTURA v2 (BLE) ---
[BLE] Anunciant com "Cadira_Postural"...
[FSR] S0=12 | S1=8 | S2=15 | S3=9 | S4=11 | S5=7  → BUIT
```

### Verificació BLE sense l'app Flutter
Utilitza **nRF Connect** (Android/iOS):
1. Escaneig → apareix `Cadira_Postural`
2. Connectar → anar a **CLIENT** → servei `6E400001-...`
3. Subscriure's a la característica TX (`6E400003-...`) → icona de campana
4. Els JSONs apareixen en temps real al camp **Value**
