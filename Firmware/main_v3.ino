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

// ── Temporització no bloquejant ──────────────────────────────────────────────
// Es fan servir millis() en lloc de delay() per no bloquejar el stack BLE.
// delay() llarg → el BLE no pot enviar keep-alive → desconnexió.
unsigned long ultimEnviament = 0;

void loop() {
  // ── Gestió de reconnexió ─────────────────────────────────────────────────
  // Quan el client es desconnecta, tornar a anunciar-se per a noves connexions.
  if (!deviceConnected && oldDeviceConnected) {
    // Espera curta NO bloquejant: el stack BLE necessita uns ms per estabilitzar
    unsigned long t = millis();
    while (millis() - t < 500) { /* yielding */ }
    pServer->startAdvertising();
    Serial.println("[BLE] Tornant a anunciar...");
    oldDeviceConnected = false;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = true;
  }

  // ── Llegir sempre els FSR (no esperar) ───────────────────────────────────
  bool ocupado = false;
  int lecturasFSR[NUM_FSR];

  for (int i = 0; i < NUM_FSR; i++) {
    for (int j = 0; j < 4; j++) {
      digitalWrite(sPins[j], (i >> j) & 0x01);
    }
    delayMicroseconds(500); // Estabilització del MUX (sense bloquejar massa)
    lecturasFSR[i] = analogRead(muxCom);
    if (lecturasFSR[i] > UMBRAL_FSR) {
      ocupado = true;
    }
  }

  // ── DEBUG: Imprimeix els valors crus dels FSR al Monitor Sèrie ───────────
  // Revisa aquests valors per saber si el MUX llegeix correctament.
  // Quan premis un FSR hauries de veure un número > 500 (fins a 4095).
  Serial.print("[FSR] ");
  for (int i = 0; i < NUM_FSR; i++) {
    Serial.print("S"); Serial.print(i); Serial.print("=");
    Serial.print(lecturasFSR[i]);
    if (i < NUM_FSR - 1) Serial.print(" | ");
  }
  Serial.print("  → ");
  Serial.println(ocupado ? "OCUPAT" : "BUIT");

  // ── Interval d'enviament: 500 ms si ocupat, 10 s si buit ─────────────────
  unsigned long interval = ocupado ? 500UL : 10000UL;
  unsigned long ara = millis();

  if (ara - ultimEnviament < interval) {
    return; // Encara no toca enviar — el loop() torna i el BLE pot respirar
  }
  ultimEnviament = ara;

  // ── ENVIAR ────────────────────────────────────────────────────────────────
  if (!ocupado) {
    String json = "{\"estat\":\"buida\"}";
    Serial.println("[BLE→] " + json);
    sendBLE(json);

  } else {
    // Leer ultrasonidos
    float distancias[NUM_US];

    for (int i = 0; i < NUM_US; i++) {
      digitalWrite(trigPin, LOW);
      delayMicroseconds(2);
      digitalWrite(trigPin, HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPin, LOW);

      long duration = pulseIn(echoPins[i], HIGH, US_TIMEOUT_US);
      float calcDist = duration * 0.034 / 2.0;

      if (duration == 0) {
        distancias[i] = DIST_MAX_CM;
      } else if (calcDist < DIST_MIN_CM) {
        distancias[i] = DIST_MIN_CM;
      } else if (calcDist > DIST_MAX_CM) {
        distancias[i] = DIST_MAX_CM;
      } else {
        distancias[i] = calcDist;
      }

      delayMicroseconds(30000); // 30 ms entre disparos (sense bloquejar massa)
    }

    // Construir JSON
    String json = "{";
    json += "\"fsrDavantEsq\":"  + String(lecturasFSR[0]) + ",";
    json += "\"fsrDavantDret\":" + String(lecturasFSR[1]) + ",";
    json += "\"fsrMigEsq\":"     + String(lecturasFSR[2]) + ",";
    json += "\"fsrMigDret\":"    + String(lecturasFSR[3]) + ",";
    json += "\"fsrDarrereEsq\":" + String(lecturasFSR[4]) + ",";
    json += "\"fsrDarrereDret\":"+ String(lecturasFSR[5]) + ",";
    json += "\"usCervical\":"    + String(distancias[0], 1) + ",";
    json += "\"usToracic\":"     + String(distancias[1], 1) + ",";
    json += "\"usLumbar\":"      + String(distancias[2], 1);
    json += "}";

    Serial.println("[BLE→] " + json);
    sendBLE(json);
  }
}
