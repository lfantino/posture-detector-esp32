# Cojín Detector de Postura / Cadira Postural

Sistema integral de hardware y software (IoT) diseñado para monitorizar y corregir la postura del usuario al sentarse. El proyecto consta de electrónica basada en un ESP32 para la adquisición de datos de sensores anatómicos y una aplicación móvil desarrollada en Flutter para la visualización y análisis del histórico postural.

## Características Principales

* **Detección de presencias (Asiento Ocupado):** Mediante una matriz de 12 sensores de presión (FSR), el cojín detecta de manera inteligente cuándo el usuario se sienta y se levanta.
* **Ahorro de Energía (Modos de Reposo / Activo):** Si no hay presión en el asiento, el sistema entra en un modo de bajo consumo o letargo, enviando lecturas cada 10 segundos para no saturar procesos ni agotar batería. Si el asiento se ocupa, aumenta la frecuencia de lectura a intervalos de ~200 - 500 ms.
* **Medición Postural Diferencial (Zonas Clave):** Utiliza 3 sensores ultrasónicos estratégicamente ubicados para medir constantemente la distancia y curvatura a tres puntos críticos de la espalda: **Cervical, Dorsal y Lumbar**.
* **Conectividad Inalámbrica Integrada:** Envío de los datos adquiridos en tiempo real por Bluetooth Serial (SSP) a un dispositivo móvil.
* **Aplicación Móvil Dedicada (Flutter):**
  * **Sistema de Autenticación:** Registro y Login de múltiples usuarios (`login_page.dart` y `register_page.dart`).
  * **Calibración Personalizada:** Funcionalidad para establecer el cero postural según la anatomía individual con `calibracion_page.dart`.
  * **Panel Sensorial:** Dashboard en tiempo real para visualizar la postura actual de forma gráfica e interactiva.
  * **Análisis Continuo:** Sección de Estadísticas para revisar la evolución del usuario con datos históricos persistentes, apoyada en base de datos local SQLite.

## Arquitectura del Repositorio

El proyecto se divide de forma modular en dos grandes bloques:

### 1. Firmware (`/Firmware`)
Contiene el código fuente programado en **C++** (compatible con entorno Arduino y PlatformIO) que corre directamente a bajo nivel sobre un microcontrolador **ESP32**. 
- Adquiere los datos analógicos de los 12 sensores FSR haciendo uso de un **multiplexor (MUX)**, reduciendo así la necesidad y saturación de pines lógicos o analógicos (ADC).
- Se encarga del *triggering* del pulso ultrasónico y lectura por `pulseIn` midiendo en microsegundos el tiempo que el eco tarda en retornar.
- Empaqueta y modula los datos mediante comas (CSV serial) y un salto de línea por actualización para que el *parsing* desde la app móvil sea seguro y estructurado.

### 2. Aplicación Móvil (`/cadira_postural`)
Una aplicación desarrollada con el framework reactivo **Flutter (Dart)**, con enfoque multiplataforma.
- **Front-end UI:** Interfaz amigable, usable y clara para el usuario final biomédico/paciente.
- **Gestión de persistencia local:** Utiliza bibliotecas como `sqflite` (SQLite en Flutter) para almacenar las sesiones de asiento, la postura y las puntuaciones derivadas por períodos.
- **Comunicación Hardware:** Desempaqueta y representa visualmente la telemetría recibida por Bluetooth de la electrónica.

## Componentes de Hardware Previstos

Para montar la versión física del dispositivo se necesitan los siguientes componentes troncales:
* **Centro neurálgico:** ESP32 Microcontroller (Soporte BT/BLE/WiFi nativo)
* **Distancia Postural:** 3x módulos sensores Ultrasónicos (Ej. HC-SR04 de corto alcance)
* **Sensores de fuerza resistivos:** 12x FSR (Force Sensitive Resistors) distribuidos sobre el asiento.
* **Expansión I/O Analógica:** 1x Módulo multiplexor (MUX) compatible (Ej. CD74HC4067 de 16 canales).

## Instalación y Despliegue

### Configurar el ESP32 (Microcontrolador)
1. Navega a los ficheros con extensión `.cpp` o `.ino` localizados en el directorio `Firmware/`.
2. Para desplegarlos usa PlatformIO o el IDE nativo de Arduino. Será necesario instalar en el "Gestor de Tarjetas/Placas" el core oficial del **ESP32**.
3. Verifica el puerto COM y flashea el archivo en la placa. Recomendamos abrir tu monitor serie en `115200` baudios para validar que los valores se están adquiriendo y emitiendo de forma adecuada. Además en Arduino IDE puedes usar la herramienta "Serial Plotter".

### Iniciar la App Móvil (Flutter)
1. Sitúate en la raíz del entorno de Flutter desde cualquier terminal de consola:
   ```bash
   cd cadira_postural
   ```
2. Obtén e instala automáticamente todas las librerías necesarias del proyecto (el equivalente al `npm install` de Flutter):
   ```bash
   flutter pub get
   ```
3. Con un emulador Android/iOS arrancado u otro dispositivo conectado por ADB a tu estación, compila y lanza la versión de debug:
   ```bash
   flutter run
   ```

---

*Proyecto diseñado con un enfoque aplicado de Ingeniería Biomédica (Tercer curso).*