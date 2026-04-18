# Guía Rápida de Pruebas (Hardware)

Pasos para verificar el funcionamiento de los sensores y el firmware ESP32:

## 1. Monitor Serie (USB)
1. Conecta la placa ESP32 y abre `Firmware/main.ino` en Arduino IDE.
2. Sube el código a la placa.
3. Abre el **Monitor Serie** y ponlo a **115200 baudios** (importante).
4. **Verifica los estados:** 
   - **Reposo:** Si no hay peso, verás `"Silla vacía - Modo Ahorro"` cada 10s.
   - **Activo:** Presiona el asiento para engañar a los FSR. Empezarán a salir los datos en tiempo real separados por comas:
     `(DistCervical, DistDorsal, DistLumbar, PresiónFSR1... PresiónFSR12)`

## 2. Bluetooth (Móvil)
1. Descarga una app genérica como **"Serial Bluetooth Terminal"** en el móvil.
2. Vincula tu móvil al Bluetooth llamado **`Cadira_Postural`** desde Ajustes.
3. Abre la app, conéctate a la placa y presiona el asiento.
4. **Verificación:** Deberás ver los mismos datos separados por comas. Si llegan, ¡el firmware está 100% listo para la app final!
