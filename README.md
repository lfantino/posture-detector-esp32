# firmware-esp32-data-adquisition

1. Definir los pines donde van conectados todas las patas de los sensores y multiplexor

Los 12 FSR conectados al multiplexor y los tres ultrasonidos a la ESP32

Cada ultrasoindos tiene cuatro pinout:
- VCC: 3V-5.5 V Power Supply
- Trig: Input pin 
- Echo: Output pin 
- GND: ground
Solo programaremos el Trig i Echo

El multiplexor tiene:
- output multiplexor: 34
- SO, S1, S2, S3 (SELECTORES)


2. Bloque codigo setup
- Definimos qué pines son input y cuales son output

3. Loop
Leer los 12 FSR para definir si alguien está sentado o no.


El código decide qué hacer basándose en la variable **ocupado**.

1. La condición principal `(if(ocupado))`
Si es true: La silla detecta presencia y empieza a recolectar datos detallados.

Si es false: Entra en el bloque else, imprimiendo "Silla vacía" y esperando 10 segundos antes de volver a revisar, ahorrando energía y procesamiento.

2. Lectura de los Sensores Utrasonido
- leer 3 sensores ultrasónicos
- El pulso: envía un disparo sónico de 10 microsegundos
- Cálculo de distancia: pulseIn para medir cuánto tarda el eco en regresar. La fórmula $distancia = \frac{duración \times 0.034}{2}$ convierte el tiempo en centímetros (basado en la velocidad del sonido).
- Salida: Envía el valor por el Puerto Serial seguido de una coma (para que se puedan almazenar en una lista)

3. Lectura los FSR


Asiento está ocupado: velocidad de medición = 500 ms

Si no hay presión la velocidad de medición es de 10s




