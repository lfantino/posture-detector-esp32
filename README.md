# Cadira Postural — Sistema IoT de Monitoratge Postural

Sistema integral de hardware i software (IoT) dissenyat per monitoritzar la postura de l'usuari mentre seu. El projecte combina electrònica basada en un **ESP32-C5** per a l'adquisició de dades de sensors anatòmics i una **aplicació mòbil Flutter** per a la visualització, anàlisi i gestió postural en temps real.

> Projecte de 3r curs d'Enginyeria Biomèdica — Grup

---

## Característiques Principals

| Característica | Descripció |
|---|---|
| **Detecció de presència** | 6 sensors FSR al seient detecten quan l'usuari seu o s'aixeca |
| **Monitoratge del respatller** | 3 sensors ultrasònics HC-SR04 mesuren la distància a les zones Cervical, Toràcica i Lumbar |
| **Transmissió sense fils** | Comunicació BLE (Bluetooth Low Energy) via Nordic UART Service (NUS) |
| **Modes d'operació** | Repòs (buit → cada 3 s) / Actiu (ocupat → cada 500 ms, ~2 Hz) |
| **App mòbil** | Flutter amb multi-usuari, calibració personalitzada, dashboard en temps real i estadístiques |
| **Persistència local** | Base de dades SQLite local al dispositiu mòbil (sense servidor extern) |

---

## Arquitectura del Repositori

```
posture-detector-esp32/
│
├── Firmware/
│   ├── main_v2.ino          ← Firmware actiu (ESP32-C5, BLE)
│   ├── main.ino             ← Versió anterior (referència)
│   └── README.md            ← Documentació tècnica del firmware
│
└── cadira_postural/         ← App Flutter
    └── lib/
        ├── main.dart
        ├── posture_control.dart      ← Lògica central (Singleton)
        ├── database/
        │   └── database_helper.dart  ← SQLite (usuaris, stats, calibracions)
        ├── services/
        │   ├── bluetooth_service.dart    ← BLE NUS (flutter_blue_plus)
        │   ├── data_averager.dart        ← Filtre de dades en temps real
        │   └── firmware_simulator.dart   ← Simulador per a tests sense hardware
        └── screens/
            ├── login_page.dart
            ├── register_page.dart
            ├── main_page.dart
            ├── dashboard_page.dart
            ├── bluetooth_page.dart
            ├── calibracion_page.dart
            ├── configuracio_page.dart
            └── estadistiques_page.dart
```

---

## Hardware Necessari

| Component | Quantitat | Funció |
|---|---|---|
| **ESP32-C5 DevKit** | 1 | Microcontrolador principal (BLE 5.0, RISC-V) |
| **Sensor FSR** (Force Sensitive Resistor) | 6 | Detecció de pressió al seient |
| **HC-SR04** (Ultrasònic) | 3 | Mesura de distància al respatller (Cervical / Toràcic / Lumbar) |
| **Multiplexor CD74HC4067** (16 canals) | 1 | Llegir els 6 FSR amb un sol pin ADC |
| **Powerbank** | 1 | Alimentació portàtil (recomanada ≥5000 mAh) |

### Connexions de pins (ESP32-C5)

**Sensores Ultrasònics:**
- `Trig` compartit → GPIO **7**
- `Echo` Cervical → GPIO **2** · Toràcic → GPIO **3** · Lumbar → GPIO **6**

**Multiplexor (MUX):**
- Sortida analògica COM → GPIO **4** (ADC)
- Selectores S0–S3 → GPIO **10, 5, 8, 28**

**LED RGB (WS2812B, keep-alive powerbank):**
- GPIO **27**

---

## Firmware (`/Firmware/main_v2.ino`)

Escrit en **C++ / Arduino** per a ESP32-C5.

### Protocol de comunicació: BLE NUS (Nordic UART Service)

> ⚠️ L'ESP32-C5 **no suporta Bluetooth Classic**. El firmware usa **BLE** (Bluetooth Low Energy) amb el Nordic UART Service (NUS), el protocol estàndard per emular UART sobre BLE.

| UUID | Rol |
|---|---|
| `6E400001-...` | Servei NUS |
| `6E400003-...` | TX Characteristic — ESP32 → App (Notify) |
| `6E400002-...` | RX Characteristic — App → ESP32 (Write) |

El JSON es fragmenta en chunks de 20 bytes (MTU base) i l'app el reassembla fins al `\n` final.

### Format JSON emès

**Seient buit** (cada 3 s):
```json
{"estat":"buida"}
```

**Seient ocupat** (cada 500 ms):
```json
{
  "fsrDavantEsq": 312,  "fsrDavantDret": 287,
  "fsrMigEsq":    301,  "fsrMigDret":    290,
  "fsrDarrereEsq":278,  "fsrDarrereDret":265,
  "usCervical": 14.2,   "usToracic": 18.5,   "usLumbar": 12.1
}
```

### Llibreries necessàries (Arduino IDE)

- Core **ESP32 by Espressif Systems ≥ 3.0.0** (inclou BLEDevice, BLEServer, BLE2902)
- **Adafruit NeoPixel** (per al LED RGB WS2812B de keep-alive)

---

## App Mòbil (`/cadira_postural`)

Desenvolupada amb **Flutter (Dart)**, compatible amb Android (mínim Android 6.0).

### Stack tecnològic

| Paquet | Versió | Funció |
|---|---|---|
| `flutter_blue_plus` | ^1.35.3 | Bluetooth Low Energy (BLE) |
| `sqflite` | any | Base de dades SQLite local |
| `permission_handler` | ^11.0.0 | Permisos BT en Android |
| `google_fonts` | ^8.1.0 | Tipografia (Outfit) |
| `uuid` | ^4.5.1 | IDs únics d'usuari |
| `intl` | ^0.19.0 | Formatació de dates |
| `image_picker` | ^1.1.2 | Avatar d'usuari |

### Flux de dades

```
ESP32-C5 (BLE Notify)
    ↓
BluetoothService  ← Parseja JSON → List<double>[9]
    ↓
DataAverager      ← rawStream (instant) + averagedStream (10 mostres)
    ↓
PostureController ← Calcula 6 criteris posturals → bonPostura (0.0–1.0)
    ↓
Dashboard UI      ← Mostra colors, alertes i estadístiques
```

### Criteris de qualitat postural (6 checks)

| Check | Descripció |
|---|---|
| `culLateralOk` | Diferència pressió esquerra/dreta ≤ threshold |
| `culFrontalOk` | Diferència pressió davant/darrere ≤ threshold |
| `cervicalOk` | `usCervical` ≤ distància màxima calibrada |
| `toracicOk` | `usToracic` ≤ distància màxima calibrada |
| `lumbarOk` | `usLumbar` ≤ distància màxima calibrada |
| `curvaturaCervicalLumbarOk` | \|usCervical – usLumbar\| ≤ 5 cm |

---

## Instal·lació i Posada en Marxa

### 1. Firmware (Arduino IDE)

1. Instal·la **Arduino IDE 2.x** → [arduino.cc/en/software](https://www.arduino.cc/en/software)
2. Afegeix el core ESP32: **Preferencias → URLs addicionals:**
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. **Gestor de Plaques** → instal·la `esp32 by Espressif Systems` **≥ 3.0.0**
4. **Gestor de Biblioteques** → instal·la `Adafruit NeoPixel`
5. Selecciona placa: **ESP32C5 Dev Module**
6. Obre `Firmware/main_v2.ino`, compila i flasheja
7. Verifica al **Monitor Sèrie** (115200 baud):
   ```
   [BLE] Anunciant com "Cadira_Postural"...
   [FSR] S0=12 | S1=8 | ... → BUIT
   ```

### 2. App Flutter

```bash
cd cadira_postural
flutter pub get
flutter run
```

**Requisits:** Flutter SDK ≥ 3.3.4, Android ≥ 6.0, permisos Bluetooth concedits al dispositiu.

### 3. Connexió BLE

1. Obre l'app → pantalla Bluetooth → **Escanejar**
2. Selecciona `Cadira_Postural` de la llista
3. Un cop connectat, el Dashboard s'actualitza en temps real

> 💡 **Verificació sense app:** Usa **nRF Connect** (Android/iOS) per connectar-te, subscriure't a la característica TX (`6E400003-...`) i veure els JSONs en temps real.

---

## Limitacions Conegudes

- Les contrasenyes d'usuari es guarden en **text pla** a la BD local (acceptable per a ús acadèmic, no per a producció).
- No hi ha **reconexió BLE automàtica** si la connexió es perd mentre l'app és oberta (cal tornar a la pantalla Bluetooth).
- El sistema no té FSR al respatller: si un ultrasònic fa timeout, s'assumeix conservadorament que la persona no està recolzada (100 cm).

---

*Projecte acadèmic d'Enginyeria Biomèdica — 3r curs, 2n semestre.*