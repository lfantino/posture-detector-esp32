# Firmware d'Adquisició de Dades (ESP32-C5)

Aquest firmware s'executa sobre un **ESP32-C5 DevKit** i gestiona el coixí intel·ligent detector de postura. Llegeix **6 sensors de pressió FSR** al seient i **3 sensors ultrasònics HC-SR04** al respatller, processa les dades i les envia per **Bluetooth Low Energy (BLE)** a l'aplicació mòbil.

## Versions disponibles

| Fitxer | Versió | Notes |
|---|---|---|
| `main.ino` | v1 | Prova inicial, sense BLE avançat |
| `main_v2.ino` | v2 | Afegeix NeoPixel keep-alive, filtre anti-zona-cega (3 lectures → mínima vàlida), `UMBRAL_FSR=400`, interval repòs=3 s |
| `main_v3.ino` | **v3 (actiu)** | Elimina NeoPixel, lectura simple d'ultrasons, `UMBRAL_FSR=500` |

> **Per flashejar:** Obre `main_v3.ino` amb Arduino IDE. Consulta la secció d'instal·lació al README principal.

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

### LED RGB WS2812B (keep-alive powerbank) — *només v2*
- GPIO **27** *(eliminat en v3)*

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

## 4. Constants de Configuració (v3)

| Constant | Valor | Descripció |
|---|---|---|
| `UMBRAL_FSR` | **500** | Valor mínim ADC (0–4095) per considerar el seient ocupat |
| `US_TIMEOUT_US` | 6000 µs | Timeout `pulseIn` (~100 cm de radi màxim) |
| `DIST_MIN_CM` | 2.0 cm | Distància mínima fiable del HC-SR04 (zona cega) |
| `DIST_MAX_CM` | 100.0 cm | Distància màxima considerada vàlida |
| `BLE_CHUNK_SIZE` | 20 bytes | Mida de fragment BLE (MTU base) |
| Interval repòs | **3 s** | Freqüència d'enviament quan el seient és buit |

> **Diferència v2:** `UMBRAL_FSR = 400` i `NUM_LECTURAS_US = 3` (filtre de mínima per anti zona-cega).

---

## 5. Configuració (`setup()`)

- Comunicació Serial a **115200 baudios** (per a debug amb Arduino IDE).
- Inicialització BLE amb nom `"Cadira_Postural"` i advertisi actiu.
- Pin `Trig` compartit com a sortida; pins `Echo` com a entrades.
- Pins selectores del MUX com a sortides.
- *v2 únicament:* LED RGB WS2812B inicialitzat en blanc (keep-alive de la powerbank).

---

## 6. Bucle Principal (`loop()`)

### 6.1. Gestió de Reconnexió BLE
Quan el client es desconnecta (`deviceConnected = false`), el firmware espera ~500 ms i reinicia l'anunci BLE automàticament.

### 6.2. Detecció de Presència (FSR del seient)
Es llegeixen els **6 canals** del multiplexor seqüencialment. Per a cada canal:
1. S'estableix el codi binari del canal als pins S0–S3.
2. Es fa un delay de 500 µs per estabilitzar el MUX.
3. Es llegeix el valor ADC amb `analogRead(muxCom)`.

Si qualsevol FSR supera `UMBRAL_FSR` (500), el sistema considera el seient com a **ocupat**.

### 6.3. Temporització no bloquejant
S'utilitza `millis()` en lloc de `delay()` llarg per no bloquejar el stack BLE:

| Estat | Interval |
|---|---|
| Seient **buit** | **3 000 ms** |
| Seient **ocupat** | **500 ms** (~2 Hz) |

### 6.4. Enviament (Seient buit)
```json
{"estat":"buida"}
```

### 6.5. Enviament (Seient ocupat)
Llegeix els 3 ultrasònics i construeix el JSON complet.

#### Lectura d'Ultrasònics (v3 — lectura simple)
Per a cada sensor:
1. Dispara el puls Trig (10 µs HIGH).
2. Mesura el temps d'eco amb `pulseIn(echoPin, HIGH, US_TIMEOUT_US)`.
3. Converteix a cm: `distancia = duration × 0.034 / 2.0`.
4. Valida el rang [2 cm, 100 cm]; si `duration == 0` → 100 cm.
5. Delay de 30 ms entre sensors per evitar cross-talk acústic.

#### Diferència respecte v2
La v2 feia **3 lectures per sensor** i agafava la **mínima vàlida** per evitar falsos 100 cm quan la persona és molt a prop (zona cega). La v3 simplifica a una sola lectura per reduir latència.

#### Validació de Lectures

| Condició | Valor assignat | Interpretació |
|---|---|---|
| `duration == 0` (timeout) | `100.0 cm` | Eco no va tornar → persona no recolzada |
| `calcDist < 2.0 cm` | `2.0 cm` | Zona cega del sensor → contacte total |
| `calcDist > 100.0 cm` | `100.0 cm` | Fora de rang clínic |
| `2.0 ≤ calcDist ≤ 100.0` | Valor mesurat | Lectura vàlida |

---

## 7. Format de Sortida JSON

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

## 8. Instal·lació i Flasheig

### Requisits previs
1. **Arduino IDE 2.x** → [arduino.cc/en/software](https://www.arduino.cc/en/software)
2. Core **ESP32 ≥ 3.0.0** — afegir URL al Gestor de Plaques:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. *(Només v2)* Llibreria **Adafruit NeoPixel** → instal·lar des del Gestor de Biblioteques

### Passos
1. Selecciona la placa: **ESP32C5 Dev Module**
2. Selecciona el port USB correcte
3. Obre `main_v3.ino`, compila (`Ctrl+R`) i flasheja (`Ctrl+U`)
4. Si l'upload falla, mantén el botó **BOOT** premut mentre comença l'upload
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
