# firmware-esp32-data-adquisition

1. **Definir los pines donde van conectados todas las patas de los sensores y multiplexor**

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


2. **Bloque codigo setup**
- Definimos qué pines son input y cuales son output

3. **Loop**
Leer los 12 FSR para definir si alguien está sentado o no.
El código decide qué hacer basándose en la variable **ocupado**. Empezamos el codigo con ocupado= false
Si los FSR del culo superan un umbral, se cambia a verdadero. Si al menos uno de esos sensores del asiento detecta una presión considerable (más de la mitad del rango si es un Arduino de 10 bits), la variable ocupado se activa.
- Si el sensor se presiona al máximo, el valor llega hasta 4095 (en ESP32).El 500 es el punto de corte.

1. La condición principal `(if(ocupado))`
Si es true: La silla detecta presencia y empieza a recolectar datos detallados.

Si es false: Entra en el bloque else, imprimiendo "Silla vacía" y esperando 10 segundos antes de volver a revisar, ahorrando energía y procesamiento.

2. Lectura de los Sensores Utrasonido
- leer 3 sensores ultrasónicos
- Limpia el pin enviando un `LOW`, luego lanza el pulso.
- El pulso: envía un disparo sónico de 10 microsegundos
- Cálculo de distancia: pulseIn para medir cuánto tarda el eco en regresar. La fórmula $distancia = \frac{duración \times 0.034}{2}$ convierte el tiempo en centímetros (basado en la velocidad del sonido y dividido entre dos porque el sonido va y vuelve).
- Salida: Envía el valor por el Puerto Serial seguido de una coma (para que se puedan almazenar en una lista)

Asiento está ocupado: velocidad de medición = 500 ms --> modo activo. Esto es suficiente para detectar si el usuario se está encorvando o cambiando de posición en tiempo real.

Si no hay presión la velocidad de medición es de 10s --> Modo Reposo. No tiene sentido medir distancias al aire constantemente, por lo que solo despierta ocasionalmente para revisar si alguien se ha sentado.


3. Lectura los FSR
El código imprime los valores de los 12 sensores de presión que ya habían sido leídos mediante el multiplexor (MUX):(Los había leído antes por encima o debajo del treshold, ahora dice el valor si el bolean es ocupado.)


4. Esto crea una lista de datos completa en una sola línea. Primeros 3: Ultrasonidos, Siguientes 12: Sensores de presión.







