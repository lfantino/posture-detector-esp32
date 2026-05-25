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
| **Modes d'operació** | Repòs (buit → cada 10 s) / Actiu (ocupat → cada 500 ms, ~2 Hz) |
| **App mòbil** | Flutter amb multi-usuari, calibració personalitzada per passos guiats amb vídeo, dashboard en temps real i estadístiques |
| **Notificacions** | Alertes locals (Android) per postura incorrecta i temps màxim assegut superat |
| **Persistència local** | Base de dades SQLite local al dispositiu mòbil (sense servidor extern) |

---

## Arquitectura del Repositori

```
firmware-esp32-data-adquisition/
│
├── Firmware/
│   ├── main_v3.ino          ← Firmware actiu (ESP32-C5, BLE) — versió actual
│   ├── main_v2.ino          ← Versió anterior (amb NeoPixel keep-alive i filtre multi-lectura)
│   ├── main.ino             ← Versió inicial (referència)
│   └── README.md            ← Documentació tècnica del firmware
│
└── cadira_postural/         ← App Flutter
    └── lib/
        ├── main.dart
        ├── posture_control.dart      ← Lògica central (Singleton, ChangeNotifier)
        ├── sensor_simulator.dart     ← Simulador de sensors (tests sense hardware)
        ├── database/
        │   └── database_helper.dart  ← SQLite (usuaris, stats, calibracions)
        ├── services/
        │   ├── bluetooth_service.dart    ← BLE NUS (flutter_blue_plus)
        │   ├── data_averager.dart        ← Filtre de dades en temps real (rawStream + averagedStream)
        │   ├── firmware_simulator.dart   ← Simulador per a tests sense hardware
        │   ├── notification_service.dart ← Notificacions locals (postura + temps assegut)
        │   └── user_session.dart         ← Sessió d'usuari actiu (Singleton)
        └── screens/
            ├── login_page.dart
            ├── register_page.dart
            ├── main_page.dart
            ├── dashboard_page.dart       ← Dashboard en temps real
            ├── bluetooth_page.dart
            ├── calibracion_page.dart     ← Calibració guiada pas a pas (6 passos + vídeos)
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

**Sensors Ultrasònics (respatller):**
- `Trig` compartit → GPIO **7**
- `Echo` Cervical → GPIO **2** · Toràcic → GPIO **3** · Lumbar → GPIO **6**

**Multiplexor CD74HC4067 (seient — canals 0–5):**
- Sortida analògica COM → GPIO **4** (ADC)
- Selectores S0–S3 → GPIO **10, 5, 8, 28**

**Mapatge de canals MUX → FSR:**

| Canal MUX | Clau JSON | Posició |
|---|---|---|
| 0 | `fsrDavantEsq` | Davant Esquerre |
| 1 | `fsrDavantDret` | Davant Dret |
| 2 | `fsrMigEsq` | Mig Esquerre |
| 3 | `fsrMigDret` | Mig Dret |
| 4 | `fsrDarrereEsq` | Darrere Esquerre |
| 5 | `fsrDarrereDret` | Darrere Dret |

> ⚠️ **v2 vs v3:** La `main_v2.ino` inclou un LED RGB WS2812B (NeoPixel, GPIO **27**) per a keep-alive de la powerbank. La `main_v3.ino` (versió actual) elimina aquest component per simplificar el circuit.

---

## Firmware (`/Firmware/`)

Escrit en **C++ / Arduino** per a ESP32-C5.

### Historial de versions

| Fitxer | Descripció |
|---|---|
| `main.ino` | v1 — Versió inicial, proves bàsiques |
| `main_v2.ino` | v2 — Afegeix NeoPixel keep-alive, filtre anti-zona-cega dels ultrasons (3 lectures → mínima vàlida), llindar FSR = 400 |
| `main_v3.ino` | **v3 (actiu)** — Elimina NeoPixel, simplifica la lectura d'ultrasons, llindar FSR = 500 |

### Protocol de comunicació: BLE NUS (Nordic UART Service)

> ⚠️ L'ESP32-C5 **no suporta Bluetooth Classic**. El firmware usa **BLE** (Bluetooth Low Energy) amb el Nordic UART Service (NUS), el protocol estàndard per emular UART sobre BLE.

| UUID | Rol |
|---|---|
| `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | Servei NUS |
| `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | TX Characteristic — ESP32 → App (Notify) |
| `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | RX Characteristic — App → ESP32 (Write) |

El JSON es fragmenta en chunks de **20 bytes** (MTU base) i l'app el reassembla fins al `\n` final.

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

### Constants de configuració (v3)

| Constant | Valor | Descripció |
|---|---|---|
| `UMBRAL_FSR` | 500 | Mínim ADC (0–4095) per considerar el seient ocupat |
| `US_TIMEOUT_US` | 6000 µs | Timeout `pulseIn` (~100 cm màx.) |
| `DIST_MIN_CM` | 2.0 cm | Zona cega del HC-SR04 |
| `DIST_MAX_CM` | 100.0 cm | Distància màxima vàlida |
| `BLE_CHUNK_SIZE` | 20 bytes | Mida de fragment per BLE (MTU base) |
| Interval repòs | 3 s | Freqüència d'enviament quan el seient és buit |

### Lògica del bucle principal (`loop()`)

1. **Lectura FSR** — Selecciona cada canal del MUX seqüencialment i llegeix el valor ADC. Si qualsevol supera `UMBRAL_FSR` → seient **ocupat**.
2. **Decisió d'interval** — 500 ms si ocupat, 3 s si buit.
3. **Enviament JSON** — Si buit: `{"estat":"buida"}` (cada 3 s). Si ocupat: llegeix els 3 ultrasònics i envia el JSON complet (cada 500 ms).
4. **Reconnexió BLE** — Quan el client es desconnecta, reinicia l'anunci automàticament.

> 💡 **Temporització no bloquejant:** S'utilitza `millis()` en lloc de `delay()` llarg per no bloquejar el stack BLE.

### Llibreries necessàries (Arduino IDE)

**v3 (actiu):**
- Core **ESP32 by Espressif Systems ≥ 3.0.0** (inclou BLEDevice, BLEServer, BLE2902)

**v2 (addicional):**
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
| `flutter_local_notifications` | — | Notificacions locals (postura + temps) |
| `video_player` | — | Vídeos guiats a la calibració |

### Flux de dades

```
ESP32-C5 (BLE Notify)
    ↓
BluetoothService  ← Parseja JSON → List<double>[9]
    ↓
DataAverager      ← rawStream (instant) + averagedStream (10 mostres)
    ↓
PostureController ← Calcula 6 criteris posturals → bonPostura (0.0–1.0)
                  ← Gestiona sessions, temps assegut i alertes
    ↓
Dashboard UI      ← Mostra colors, alertes i estadístiques
```

### Criteris de qualitat postural (6 checks)

| Check | Descripció |
|---|---|
| `culLateralOk` | Diferència pressió esquerra/dreta ≤ threshold calibrat |
| `culFrontalOk` | Diferència pressió davant/darrere ≤ threshold calibrat (només es penalitza si davant > darrere) |
| `cervicalOk` | `usCervical` ≤ distància màxima calibrada |
| `toracicOk` | `usToracic` ≤ distància màxima calibrada |
| `lumbarOk` | `usLumbar` ≤ distància màxima calibrada |
| `curvaturaCervicalLumbarOk` | \|usCervical – usLumbar\| ≤ threshold calibrat |

La puntuació global (`bonPostura`) és el nombre de checks correctes dividit per 6 → rang 0.0–1.0.

### Calibració personalitzada (6 passos)

La pantalla de calibració guia l'usuari amb **vídeos explicatius** per a cada pas:

| Pas | Acció | Threshold calculat |
|---|---|---|
| 1 | Postura de referència (esquena recta) | Referència de distàncies Cervical/Toràcic/Lumbar |
| 2 | Seient a la vora (davant) | `maxDiferenciaFrontal` = diferència × 0.65 |
| 3 | Pes a la dreta (cama esquerra sobre dreta) | Referència lateral dreta |
| 4 | Pes a l'esquerra (cama dreta sobre esquerra) | `maxDiferenciaLateralCul` = mínima de les dues × 0.9 |
| 5 | Esquena separada del respatller | `maxDistanciaCervical/Toràcic/Lumbar` |
| 6 | Inclinació cap endavant | `maxDiferenciaCervicalLumbar` ≥ 4.0 cm |

Els thresholds es guarden a la base de dades SQLite i es carreguen automàticament a l'inici de sessió.

### Notificacions

| Canal | Trigger | Missatge |
|---|---|---|
| `posture_alerts` | `bonPostura < 0.7` o qualsevol check falla | "Postura incorrecta detectada" |
| `sitting_time_alerts` | Temps assegut ≥ objectiu configurat (min) | "És hora d'aixecar-se!" |

Les notificacions s'envien una sola vegada per sessió/alerta (no spam). L'usuari pot desactivar-les des de Configuració.

---

## Instal·lació i Posada en Marxa

### 1. Firmware (Arduino IDE)

1. Instal·la **Arduino IDE 2.x** → [arduino.cc/en/software](https://www.arduino.cc/en/software)
2. Afegeix el core ESP32: **Preferencias → URLs addicionals:**
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. **Gestor de Plaques** → instal·la `esp32 by Espressif Systems` **≥ 3.0.0**
4. Selecciona placa: **ESP32C5 Dev Module**
5. Obre `Firmware/main_v3.ino`, compila (`Ctrl+R`) i flasheja (`Ctrl+U`)
6. Si el upload falla, mantén el botó **BOOT** premut mentre comença l'upload
7. Verifica al **Monitor Sèrie** (115200 baud):
   ```
   --- SISTEMA DE POSTURA v2 (BLE) ---
   [BLE] Anunciant com "Cadira_Postural"...
   [FSR] S0=12 | S1=8 | S2=15 | S3=9 | S4=11 | S5=7  → BUIT
   ```

> 💡 Si vols el keep-alive del LED per a la powerbank, usa `main_v2.ino` i instal·la també la llibreria **Adafruit NeoPixel**.

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

### 4. Calibració

Després de connectar, accedeix a la pestanya **Calibració** i segueix els 6 passos guiats. La calibració adapta els thresholds de postura a l'anatomia i preferències de cada usuari. **És recomanable calibrar abans del primer ús.**

---

## Limitacions Conegudes

- Les contrasenyes d'usuari es guarden en **text pla** a la BD local (acceptable per a ús acadèmic, no per a producció).
- No hi ha **reconnexió BLE automàtica** si la connexió es perd mentre l'app és oberta (cal tornar a la pantalla Bluetooth).
- El sistema no té FSR al respatller: si un ultrasònic fa timeout, s'assumeix conservadorament que la persona no està recolzada (100 cm).
- Les notificacions locals estan implementades **únicament per Android**. iOS requereix configuració addicional (APNs).
- Els vídeos de calibració (`assets/videos/pas1.mp4` … `pas6.mp4`) han d'existir al directori `assets/` de l'app; si no hi són, la pantalla mostra un missatge d'error sense bloquejar el flux.

---

*Projecte acadèmic d'Enginyeria Biomèdica — 3r curs, 2n semestre.*