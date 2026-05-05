#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// -----------------------------------------------------------------------
// UUIDs — Nordic UART Service (NUS)
// Protocol obert estàndard per emular una UART sobre BLE.
// Idèntics al flutter_blue_plus (bluetooth_service.dart).
// -----------------------------------------------------------------------
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHAR_UUID_TX                                                           \
  "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" // ESP32 → App (Notify)
#define CHAR_UUID_RX                                                           \
  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // App → ESP32 (Write)

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
const int muxCom = 4;               // Salida analógica del MUX → ESP32
const int sPins[] = {10, 5, 8, 28}; // Selectores S0–S3 del MUX

// -----------------------------------------------------------------------
// CONSTANTES DE CONFIGURACIÓN
// -----------------------------------------------------------------------
const int NUM_FSR = 6;
const int NUM_US = 3;
const int UMBRAL_FSR =
    500; // Valor mínimo (0–4095) para considerar asiento ocupado
const int US_TIMEOUT_US =
    6000; // Timeout pulseIn en µs (~100 cm de alcance máximo)
const float DIST_MIN_CM =
    2.0; // Distancia mínima fiable del HC-SR04 (zona ciega)
const float DIST_MAX_CM = 100.0; // Distancia máxima considerada válida

// -----------------------------------------------------------------------
// BLE — Variables globals
// -----------------------------------------------------------------------
BLEServer *pServer = nullptr;
BLECharacteristic *pTxChar = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// -----------------------------------------------------------------------
// BLE — Callbacks de connexió i desconnexió del client
// -----------------------------------------------------------------------
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) override {
    deviceConnected = true;
    Serial.println("[BLE] Client connectat");
  }
  void onDisconnect(BLEServer *pServer) override {
    deviceConnected = false;
    Serial.println("[BLE] Client desconnectat");
  }
};

// -----------------------------------------------------------------------
// sendBLE() — Envia un String pel canal BLE (TX Notify)
//
// BLE té un límit de payload per paquet. Per compatibilitat amb qualsevol
// dispositiu (MTU base = 20 bytes), el JSON es fragmenta en trossos de 20
// bytes. L'app acumula els fragments fins al '\n' final per reassemblar-lo.
// -----------------------------------------------------------------------
const int BLE_CHUNK_SIZE = 20;

void sendBLE(const String &data) {
  if (!deviceConnected)
    return;

  // Afegir '\n' al final per indicar a l'app el final del missatge
  String payload = data + "\n";
  int len = payload.length();
  int offset = 0;

  while (offset < len) {
    int chunkLen = min(BLE_CHUNK_SIZE, len - offset);
    pTxChar->setValue((uint8_t *)(payload.c_str() + offset), chunkLen);
    pTxChar->notify();
    offset += chunkLen;
    delay(10); // Petit delay per no saturar la cua BLE interna
  }
}

void setup() {
  Serial.begin(115200);

  // ── Configurar pins de sensors ────────────────────────────────────────
  pinMode(trigPin, OUTPUT);
  for (int i = 0; i < NUM_US; i++) {
    pinMode(echoPins[i], INPUT);
  }
  for (int i = 0; i < 4; i++) {
    pinMode(sPins[i], OUTPUT);
  }

  // ── Inicialitzar BLE ──────────────────────────────────────────────────
  BLEDevice::init("Cadira_Postural");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Crear servei NUS
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Característica TX (ESP32 → App): Notify
  pTxChar = pService->createCharacteristic(CHAR_UUID_TX,
                                           BLECharacteristic::PROPERTY_NOTIFY);
  pTxChar->addDescriptor(new BLE2902()); // Requerit per activar notificacions

  // Característica RX (App → ESP32): Write
  // No s'usa activament ara, però és part de l'estàndard NUS
  BLECharacteristic *pRxChar = pService->createCharacteristic(
      CHAR_UUID_RX,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  (void)pRxChar; // Evitar warning de variable no usada

  pService->start();

  // Anunciar-se per a que els clients el trobin
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // Ajuda amb la connexió en iOS
  BLEDevice::startAdvertising();

  Serial.println("--- SISTEMA DE POSTURA v2 (BLE) ---");
  Serial.println("Asiento: 6 FSR via MUX | Respaldo: 3 Ultrasonidos");
  Serial.println("[BLE] Anunciant com \"Cadira_Postural\"...");
}

void loop() {
  // ── Gestió de reconnexió ─────────────────────────────────────────────
  // Quan el client es desconnecta, tornar a anunciar-se per a noves connexions.
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Espera breu per estabilitzar el stack BLE
    pServer->startAdvertising();
    Serial.println("[BLE] Tornant a anunciar...");
    oldDeviceConnected = false;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = true;
  }

  bool ocupado = false;
  int lecturasFSR[NUM_FSR];

  // -----------------------------------------------------------------------
  // PASO 1: Leer los 6 FSR del asiento via multiplexor
  // El asiento se considera OCUPADO si cualquier FSR supera el umbral.
  // -----------------------------------------------------------------------
  for (int i = 0; i < NUM_FSR; i++) {
    for (int j = 0; j < 4; j++) {
      digitalWrite(sPins[j], (i >> j) & 0x01);
    }
    delay(2);
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
    sendBLE(json);
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
      // VALIDACIÓ DE LECTURES ULTRASÒNIQUES
      //
      //  · duration == 0 (timeout):  persona NO apoyada → 100.0 cm
      //  · calcDist < DIST_MIN_CM:   zona ciega del sensor → 2.0 cm
      //  · calcDist > DIST_MAX_CM:   fuera de rango → 100.0 cm
      //  · Lectura válida (2.0–100.0 cm): se usa directamente
      // -------------------------------------------------------------------
      if (duration == 0) {
        distancias[i] = DIST_MAX_CM;
      } else if (calcDist < DIST_MIN_CM) {
        distancias[i] = DIST_MIN_CM;
      } else if (calcDist > DIST_MAX_CM) {
        distancias[i] = DIST_MAX_CM;
      } else {
        distancias[i] = calcDist;
      }

      delay(30); // Espera entre disparos para evitar interferencias
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

    json += "\"fsrDavantEsq\":" + String(lecturasFSR[0]) + ",";
    json += "\"fsrDavantDret\":" + String(lecturasFSR[1]) + ",";
    json += "\"fsrMigEsq\":" + String(lecturasFSR[2]) + ",";
    json += "\"fsrMigDret\":" + String(lecturasFSR[3]) + ",";
    json += "\"fsrDarrereEsq\":" + String(lecturasFSR[4]) + ",";
    json += "\"fsrDarrereDret\":" + String(lecturasFSR[5]) + ",";

    json += "\"usCervical\":" + String(distancias[0], 1) + ",";
    json += "\"usToracic\":" + String(distancias[1], 1) + ",";
    json += "\"usLumbar\":" + String(distancias[2], 1);

    json += "}";

    Serial.println(json);
    sendBLE(json);

    delay(500); // Frecuencia de muestreo: ~2 Hz en modo activo
  }
}
