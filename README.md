## 🧪 Prueba del sensor ultrasónico (sin hardware)

Este proyecto permite activar audio automáticamente al detectar proximidad a una obra mediante un sensor ultrasónico conectado a un ESP32. Para pruebas sin el dispositivo físico, se puede simular el funcionamiento modificando manualmente los valores en Firebase.

---

### 📍 Ruta Firebase para la prueba

El ESP32 sube la distancia medida a esta ruta:

```bash

/sensor/galeriai/amanecer/distancia

```

- `galeriai` = nombre normalizado de la galería
- `amanecer` = nombre normalizado de la pintura

---

### 🔊 ¿Qué sucede si alguien se acerca?

Cuando la distancia es **menor al umbral de activación** (`30 cm`), la app activa automáticamente la descripción por voz usando TTS (`flutter_tts`).

---

### 📥 Cómo simular la detección de cercanía

1. Ingresar a `Firebase Console`
2. Abrir el proyecto asociado a este repositorio
3. Ir a `Realtime Database`
4. Navegar a la siguiente ruta o crearla si no existe:
5. Cambiar el valor manualmente a un número **menor a 30**, por ejemplo:

```json

"distancia": 14

```

6. Abrir la app Flutter y seleccionar la pintura "Amanecer" de la galería "Galería I".

7. Observar que en consola se imprimen logs como:

```bash

🟡 Evento onValue: 14
📌 ¿Está dentro de rango? Sí
🔈 Reproduciendo descripción por TTS...

```

Y se reproduce el audio con la descripción de la obra.

---

## 🔌 Conexión con hardware (sensor ultrasónico + ESP32)

Si deseas realizar la prueba física del sistema usando un **sensor ultrasónico (HC-SR04)** y una **placa ESP32**, sigue estas instrucciones:

---

### 🔧 Conexiones físicas

| Sensor HC-SR04 | ESP32         |
|----------------|---------------|
| **VCC**        | 5V            |
| **GND**        | GND           |
| **TRIG**       | GPIO 12 (TRIG_PIN) |
| **ECHO**       | GPIO 14 (ECHO_PIN) |

> Estos pines están definidos en el código (assets/sensor_esp32.ino) como:

```cpp
#define TRIGGER_PIN 12
#define ECHO_PIN 14
```
---

### 🧠 Cómo cargar el código al ESP32

1. Instala el `Arduino IDE`si no lo tienes.

2. Agrega soporte para ESP32:

   - Ve a **Preferencias** y en "Gestor de URLs adicionales" agrega:
     ```
     https://dl.espressif.com/dl/package_esp32_index.json
     ```
   - Luego abre **Gestor de placas**, busca e instala `esp32 by Espressif Systems`.

3. Instala estas bibliotecas:
   - Firebase ESP Client
   - NewPing

4. Abre el archivo `sensor_esp32.ino` desde el Arduino IDE

5. Edita y reemplaza:

   ```cpp
   #define WIFI_SSID "TU_WIFI"
   #define WIFI_PASSWORD "TU_PASSWORD"
   #define API_KEY "TU_API_KEY"
   #define DATABASE_URL "https://tuproyecto.firebaseio.com"
   ```