// #include <WiFi.h>
// #include <Firebase_ESP_Client.h>
// #include <NewPing.h>

// 🔌 WiFi
// #define WIFI_SSID "Familia Unida 2.4 GHZ"
// #define WIFI_PASSWORD "Mandril2000#"

// 🔐 Firebase
// #define API_KEY "AIzaSyDpXCHbi1i7bpxnG7hyICxRgKXo9z1nY1c"
// #define DATABASE_URL "https://beaconlocalization-default-rtdb.firebaseio.com"
// #define USER_EMAIL "rparedesba@unsa.edu.pe"
// #define USER_PASSWORD "462216431945"

// 📏 Sensor ultrasónico
// #define TRIGGER_PIN 12
// #define ECHO_PIN 14
// #define MAX_DISTANCE 200
// #define UMBRAL_PROXIMIDAD 30  // cm

// #define GALLERY_ID "galeriai"
// #define PAINTING_ID "amanecer"

// ⏱️ Tiempos
// unsigned long sendDataPrevMillis = 0;
// unsigned long intervalo = 1000;  // cada 1s

// 🧠 Firebase
// FirebaseData fbdo;
// FirebaseAuth auth;
// FirebaseConfig config;

// 📊 Estado
// NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE);
// unsigned int ultimaDistancia = 999;
// bool ultimoEstadoAudio = false;

// void setup() {
//   Serial.begin(115200);
//   delay(1000);

//   🌐 Conexión WiFi
//   WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
//   Serial.print("🔌 Conectando al WiFi");
//   while (WiFi.status() != WL_CONNECTED) {
//     Serial.print(".");
//     delay(500);
//   }
//   Serial.println("\n✅ WiFi conectado");

//   🔧 Configurar Firebase
//   config.api_key = API_KEY;
//   config.database_url = DATABASE_URL;
//   auth.user.email = USER_EMAIL;
//   auth.user.password = USER_PASSWORD;

//   Firebase.begin(&config, &auth);
//   Firebase.reconnectWiFi(true);
//   Serial.println("📡 Firebase configurado");
// }

// void loop() {
//   if (millis() - sendDataPrevMillis > intervalo) {
//     sendDataPrevMillis = millis();

//     unsigned int distancia = sonar.ping_cm();
//     Serial.print("📏 Distancia actual: ");
//     Serial.print(distancia);
//     Serial.println(" cm");

//     if (!Firebase.ready()) return;

//     📤 Enviar valor actual siempre
//     bool ok = Firebase.RTDB.setInt(&fbdo, "/sensor/" GALLERY_ID "/" PAINTING_ID "/distancia", distancia);
//     if (ok) {
//       Serial.println("✅ Distancia actualizada en Firebase");
//     } else {
//       Serial.print("❌ Error al enviar: ");
//       Serial.println(fbdo.errorReason());
//     }

//     🎛️ Actuador: activar audio si el visitante se acerca
//     bool activarAudio = (distancia > 0 && distancia < UMBRAL_PROXIMIDAD);

//     Evitar escribir si no ha cambiado
//     if (activarAudio != ultimoEstadoAudio) {
//       bool exito = Firebase.RTDB.setBool(&fbdo, "/control/" GALLERY_ID "/" PAINTING_ID "/habilitarAudio", activarAudio);
//       if (exito) {
//         Serial.print("🎚️ habilitarAudio actualizado: ");
//         Serial.println(activarAudio ? "true" : "false");
//         ultimoEstadoAudio = activarAudio;
//       } else {
//         Serial.print("❌ Error al escribir habilitarAudio: ");
//         Serial.println(fbdo.errorReason());
//       }
//     }
//   }
// }
