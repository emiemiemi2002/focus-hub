/*
 * Focus Hub: Estación de Productividad Sincronizada (IoT)
 * Firmware para ESP32
 */

// ============================================================================
// 1. INCLUSIÓN DE BIBLIOTECAS
// ============================================================================
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>
#include <vector>
#include "secrets.h"

// ============================================================================
// 2. CONFIGURACIÓN DE HARDWARE
// ============================================================================
#define PIN_OLED_SDA 21
#define PIN_OLED_SCL 22
#define PIN_POT 34
#define PIN_BTN_1 18 // Verde (Start/Complete)
#define PIN_BTN_2 19 // Amarillo (Pause/Break)
#define PIN_BTN_3 5  // Rojo (Cancel)
#define PIN_LED_1 25 // Verde
#define PIN_LED_2 26 // Amarillo
#define PIN_LED_3 27 // Rojo
#define PIN_BUZZER 23

// ============================================================================
// 3. OBJETOS GLOBALES
// ============================================================================
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);

// ============================================================================
// 4. DEFINICIONES AWS (TOPICS)
// ============================================================================
// Topic donde llegan los cambios (Deltas)
#define AWS_TOPIC_SHADOW_DELTA "$aws/things/" THINGNAME "/shadow/update/delta"
// Topic donde enviamos nuestro estado
#define AWS_TOPIC_SHADOW_UPDATE "$aws/things/" THINGNAME "/shadow/update"
// Topic donde solicitamos el estado inicial
#define AWS_TOPIC_SHADOW_GET "$aws/things/" THINGNAME "/shadow/get"
// Topic donde llega la respuesta del estado inicial
#define AWS_TOPIC_SHADOW_GET_ACCEPTED "$aws/things/" THINGNAME "/shadow/get/accepted"
// Topic personalizado para completar tareas
#define AWS_TOPIC_COMPLETE "focushub/complete"

// ============================================================================
// 5. ESTADO GLOBAL
// ============================================================================
struct Task { String id; String name; };
std::vector<Task> tasks;
int selectedTaskIndex = 0;
int lastPotValue = 0;

enum State { STATE_CONNECTING, STATE_IDLE, STATE_FOCUS, STATE_BREAK, STATE_PAUSED };
State currentState = STATE_CONNECTING;
State prePauseState = STATE_IDLE;

// ============================================================================
// 6. TEMPORIZADORES
// ============================================================================
unsigned long timerStartMillis = 0;
unsigned long timerDuration = 0;
unsigned long remainingTimeAtPause = 0;

// Duraciones (Ajustar según necesidad)
#define DURATION_POMODORO (5 * 60 * 1000)
#define DURATION_BREAK    (1 * 60 * 1000)

#define LONG_PRESS_MS 2000
unsigned long btn1PressTime = 0;
bool btn1LongPressTriggered = false;

// ============================================================================
// 7. SISTEMA DE SONIDO
// ============================================================================
#define SOUND_STARTUP 0
#define SOUND_FOCUS_START 1
#define SOUND_BREAK_START 2
#define SOUND_COMPLETE 3
#define SOUND_ALARM 4
#define SOUND_CLICK 5
#define SOUND_PAUSE 6
#define SOUND_RESUME 7

void playPattern(int pattern) {
  switch (pattern) {
    case SOUND_STARTUP:
      for(int i=0; i<3; i++) { digitalWrite(PIN_BUZZER, HIGH); delay(50); digitalWrite(PIN_BUZZER, LOW); delay(50); }
      break;
    case SOUND_FOCUS_START:
      digitalWrite(PIN_BUZZER, HIGH); delay(800); digitalWrite(PIN_BUZZER, LOW);
      break;
    case SOUND_BREAK_START:
      digitalWrite(PIN_BUZZER, HIGH); delay(100); digitalWrite(PIN_BUZZER, LOW); delay(100);
      digitalWrite(PIN_BUZZER, HIGH); delay(100); digitalWrite(PIN_BUZZER, LOW);
      break;
    case SOUND_COMPLETE:
      digitalWrite(PIN_BUZZER, HIGH); delay(100); digitalWrite(PIN_BUZZER, LOW); delay(50);
      digitalWrite(PIN_BUZZER, HIGH); delay(100); digitalWrite(PIN_BUZZER, LOW); delay(50);
      digitalWrite(PIN_BUZZER, HIGH); delay(400); digitalWrite(PIN_BUZZER, LOW);
      break;
    case SOUND_ALARM:
      for(int i=0; i<3; i++) { digitalWrite(PIN_BUZZER, HIGH); delay(300); digitalWrite(PIN_BUZZER, LOW); delay(200); }
      break;
    case SOUND_CLICK:
      digitalWrite(PIN_BUZZER, HIGH); delay(20); digitalWrite(PIN_BUZZER, LOW);
      break;
    case SOUND_PAUSE:
      digitalWrite(PIN_BUZZER, HIGH); delay(200); digitalWrite(PIN_BUZZER, LOW); delay(50);
      digitalWrite(PIN_BUZZER, HIGH); delay(50); digitalWrite(PIN_BUZZER, LOW);
      break;
    case SOUND_RESUME:
      digitalWrite(PIN_BUZZER, HIGH); delay(50); digitalWrite(PIN_BUZZER, LOW); delay(50);
      digitalWrite(PIN_BUZZER, HIGH); delay(200); digitalWrite(PIN_BUZZER, LOW);
      break;
  }
}

// ============================================================================
// 8. PROTOTIPOS
// ============================================================================
void setupWiFi(); void setupAWS(); void connectAWS(); void reconnectAWS();
void awsCallback(char* topic, byte* payload, unsigned int length);
void reportCurrentStateToShadow(); void publishTaskComplete(String taskId);
void handlePotentiometer(); void handleButtons(); void updateDisplay();
void startTimer(State newState, unsigned long duration);
void setLedsForState(State state);

// ============================================================================
// 9. SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  Wire.begin(PIN_OLED_SDA, PIN_OLED_SCL);
  pinMode(PIN_POT, INPUT);
  pinMode(PIN_BTN_1, INPUT_PULLUP); pinMode(PIN_BTN_2, INPUT_PULLUP); pinMode(PIN_BTN_3, INPUT_PULLUP);
  pinMode(PIN_LED_1, OUTPUT); pinMode(PIN_LED_2, OUTPUT); pinMode(PIN_LED_3, OUTPUT); pinMode(PIN_BUZZER, OUTPUT);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { for(;;); }
  
  // Pantalla de inicio
  display.clearDisplay(); display.setTextSize(1); display.setTextColor(WHITE);
  display.setCursor(0,0); display.println("Focus Hub V4"); display.display();
  
  playPattern(SOUND_STARTUP);

  setupWiFi();
  setupAWS();
  
  currentState = STATE_IDLE;
  setLedsForState(STATE_IDLE);
}

// ============================================================================
// 10. LOOP
// ============================================================================
void loop() {
  if (!client.connected()) { reconnectAWS(); }
  client.loop();

  handlePotentiometer();
  handleButtons();

  // Lógica de Fin de Temporizador
  if (currentState == STATE_FOCUS || currentState == STATE_BREAK) {
    if (millis() - timerStartMillis >= timerDuration) {
      playPattern(SOUND_ALARM);
      currentState = STATE_IDLE;
      setLedsForState(STATE_IDLE);
      reportCurrentStateToShadow();
    }
  }

  // Lógica LED Pausa (Parpadeo)
  if (currentState == STATE_PAUSED) {
    if ((millis() % 1000) < 500) digitalWrite(PIN_LED_2, HIGH);
    else digitalWrite(PIN_LED_2, LOW);
    digitalWrite(PIN_LED_1, LOW); digitalWrite(PIN_LED_3, LOW);
  }

  // Actualizar Pantalla
  static unsigned long lastUpdate = 0;
  if (millis() - lastUpdate > 100) {
    updateDisplay();
    lastUpdate = millis();
  }
}

// ============================================================================
// 11. MANEJADORES DE UI
// ============================================================================
void handlePotentiometer() {
  if (currentState != STATE_IDLE || tasks.empty()) return;
  int potValue = analogRead(PIN_POT);
  if (abs(potValue - lastPotValue) > 60) {
    lastPotValue = potValue;
    selectedTaskIndex = map(potValue, 0, 4095, 0, tasks.size());
    if (selectedTaskIndex >= tasks.size()) selectedTaskIndex = tasks.size() - 1;
    if (selectedTaskIndex < 0) selectedTaskIndex = 0;
  }
}

void handleButtons() {
  // --- BOTÓN 1 (VERDE) ---
  if (digitalRead(PIN_BTN_1) == LOW) {
    if (btn1PressTime == 0) { btn1PressTime = millis(); btn1LongPressTriggered = false; }
    
    // Detección de Pulsación Larga (COMPLETAR TAREA)
    if (!btn1LongPressTriggered && (millis() - btn1PressTime > LONG_PRESS_MS)) {
      btn1LongPressTriggered = true;
      if ((currentState == STATE_FOCUS || currentState == STATE_IDLE) && !tasks.empty()) {
         // 1. Feedback Auditivo
         playPattern(SOUND_COMPLETE);
         
         // 2. Enviar a la Nube
         publishTaskComplete(tasks[selectedTaskIndex].id);
         
         // 3. ACTUALIZACIÓN OPTIMISTA (UI LOCAL) - NUEVO EN V4
         // Borramos la tarea de la lista local inmediatamente para que desaparezca de la pantalla.
         // No esperamos a que la nube nos confirme.
         tasks.erase(tasks.begin() + selectedTaskIndex);
         
         // Ajustamos el índice por si borramos la última tarea
         if (selectedTaskIndex >= tasks.size() && !tasks.empty()) {
           selectedTaskIndex = tasks.size() - 1;
         }
         
         // 4. Resetear Estado
         currentState = STATE_IDLE;
         setLedsForState(STATE_IDLE);
         reportCurrentStateToShadow();
      }
    }
  } else {
    if (btn1PressTime != 0 && !btn1LongPressTriggered) {
      // Pulsación Corta (INICIAR FOCUS)
      if (currentState == STATE_IDLE && !tasks.empty()) {
        playPattern(SOUND_FOCUS_START);
        startTimer(STATE_FOCUS, DURATION_POMODORO);
      }
    }
    btn1PressTime = 0;
  }

  // --- BOTÓN 2 (AMARILLO - PAUSA) ---
  static bool btn2LastState = HIGH;
  bool btn2State = digitalRead(PIN_BTN_2);
  if (btn2LastState == HIGH && btn2State == LOW) {
    playPattern(SOUND_CLICK); // Feedback
    if (currentState == STATE_FOCUS || currentState == STATE_BREAK) {
      // Pausar
      playPattern(SOUND_PAUSE);
      prePauseState = currentState;
      remainingTimeAtPause = timerDuration - (millis() - timerStartMillis);
      currentState = STATE_PAUSED;
      reportCurrentStateToShadow();
    } else if (currentState == STATE_PAUSED) {
      // Reanudar
      playPattern(SOUND_RESUME);
      currentState = prePauseState;
      timerStartMillis = millis() - (timerDuration - remainingTimeAtPause);
      setLedsForState(currentState);
      reportCurrentStateToShadow();
    } else if (currentState == STATE_IDLE) {
      // Iniciar Descanso
      playPattern(SOUND_BREAK_START);
      startTimer(STATE_BREAK, DURATION_BREAK);
    }
  }
  btn2LastState = btn2State;

  // --- BOTÓN 3 (ROJO - CANCELAR) ---
  static bool btn3LastState = HIGH;
  bool btn3State = digitalRead(PIN_BTN_3);
  if (btn3LastState == HIGH && btn3State == LOW) {
    playPattern(SOUND_CLICK);
    if (currentState != STATE_IDLE && currentState != STATE_CONNECTING) {
      currentState = STATE_IDLE;
      digitalWrite(PIN_LED_1, LOW); digitalWrite(PIN_LED_2, LOW); digitalWrite(PIN_LED_3, HIGH);
      delay(500);
      setLedsForState(STATE_IDLE);
      reportCurrentStateToShadow();
    }
  }
  btn3LastState = btn3State;
}

// ============================================================================
// 12. AUXILIARES
// ============================================================================
void startTimer(State newState, unsigned long duration) {
  currentState = newState;
  timerDuration = duration;
  timerStartMillis = millis();
  setLedsForState(currentState);
  reportCurrentStateToShadow();
}

void setLedsForState(State state) {
  digitalWrite(PIN_LED_1, LOW); digitalWrite(PIN_LED_2, LOW); digitalWrite(PIN_LED_3, LOW);
  switch (state) {
    case STATE_FOCUS: digitalWrite(PIN_LED_1, HIGH); break;
    case STATE_BREAK: digitalWrite(PIN_LED_2, HIGH); break;
    case STATE_IDLE: case STATE_CONNECTING: break;
    case STATE_PAUSED: break; // Manejado en loop
  }
}

void updateDisplay() {
  display.clearDisplay();
  if (currentState == STATE_CONNECTING) {
    display.setCursor(0, 0); display.println("Conectando..."); display.display(); return;
  }

  display.setTextSize(1); display.setCursor(0,0);
  switch(currentState) {
    case STATE_IDLE:   display.print("LISTA DE TAREAS"); break;
    case STATE_FOCUS:  display.print("MODO FOCUS"); break;
    case STATE_BREAK:  display.print("TIEMPO DESCANSO"); break;
    case STATE_PAUSED: display.print(" >> PAUSADO << "); break;
  }
  display.drawLine(0, 10, 128, 10, WHITE);

  if (currentState == STATE_IDLE) {
    if (tasks.empty()) {
      display.setCursor(0, 25); display.println("Sin tareas.");
    } else {
      int start = 0; if (selectedTaskIndex > 2) start = selectedTaskIndex - 2;
      for (int i = start; i < tasks.size() && i < start + 4; i++) {
        display.setCursor(0, 15 + (i - start) * 10);
        display.print(i == selectedTaskIndex ? "> " : "  ");
        display.println(tasks[i].name.substring(0, 18));
      }
    }
  } else {
    // Timer
    long remaining;
    if (currentState == STATE_PAUSED) remaining = remainingTimeAtPause;
    else remaining = timerDuration - (millis() - timerStartMillis);
    if (remaining < 0) remaining = 0;

    int minutes = (remaining / 1000) / 60;
    int seconds = (remaining / 1000) % 60;

    display.setTextSize(3); display.setCursor(20, 25);
    if (minutes < 10) display.print("0"); display.print(minutes);
    display.print(":");
    if (seconds < 10) display.print("0"); display.print(seconds);
    
    if ((currentState == STATE_FOCUS || (currentState == STATE_PAUSED && prePauseState == STATE_FOCUS)) && !tasks.empty()) {
      display.setTextSize(1); display.setCursor(0, 55);
      // Validación extra de seguridad
      if (selectedTaskIndex < tasks.size()) {
        String name = tasks[selectedTaskIndex].name;
        int pad = (21 - name.length()) / 2; for(int k=0; k<pad; k++) display.print(" ");
        display.println(name);
      }
    }
  }
  display.display();
}

// ============================================================================
// 13. CONECTIVIDAD (AWS) - FIX ARRANQUE V4
// ============================================================================
void setupWiFi() {
  display.clearDisplay(); display.setCursor(0,0); display.println("Conectando WiFi..."); display.display();
  WiFi.mode(WIFI_STA); WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("OK");
}

void setupAWS() {
  net.setCACert(AWS_CERT_CA); net.setCertificate(AWS_CERT_CRT); net.setPrivateKey(AWS_CERT_PRIVATE);
  client.setServer(AWS_IOT_ENDPOINT, 8883);
  client.setCallback(awsCallback);
  client.setBufferSize(4096);
  connectAWS();
}

void connectAWS() {
  while (!client.connected()) {
    if (client.connect((THINGNAME + String(random(0xffff), HEX)).c_str())) {
      Serial.println("Conectado a AWS.");
      // 1. Suscribirse a DELTA (para cambios en tiempo real)
      client.subscribe(AWS_TOPIC_SHADOW_DELTA);
      
      // 2. NUEVO EN V4: Suscribirse a GET/ACCEPTED
      // Aquí es donde AWS envía la respuesta con el estado inicial completo.
      client.subscribe(AWS_TOPIC_SHADOW_GET_ACCEPTED);
      
      // 3. Solicitar el estado inicial inmediatamente
      client.publish(AWS_TOPIC_SHADOW_GET, "");
    } else { delay(2000); }
  }
}

void reconnectAWS() { if (!client.connected()) connectAWS(); }

// Función auxiliar para procesar JSON de tareas (reutilizable)
void processTasksJson(JsonObject state) {
  // Buscamos la lista de tareas dentro del objeto JSON.
  // A veces viene directo, a veces dentro de "desired".
  JsonArray tasksArray;
  
  if (state.containsKey("tasks")) {
    tasksArray = state["tasks"];
  } else if (state.containsKey("desired") && state["desired"].containsKey("tasks")) {
    tasksArray = state["desired"]["tasks"];
  } else {
    return; // No hay tareas
  }

  Serial.println("Actualizando lista de tareas...");
  tasks.clear();
  for (JsonObject t : tasksArray) {
    tasks.push_back({t["id"] | "x", t["name"] | "?"});
  }
  if (selectedTaskIndex >= tasks.size()) selectedTaskIndex = 0;
  updateDisplay(); // Forzar actualización visual
}

void awsCallback(char* topic, byte* payload, unsigned int length) {
  String topicStr = String(topic);
  Serial.print("Mensaje en: "); Serial.println(topicStr);

  DynamicJsonDocument doc(4096);
  DeserializationError err = deserializeJson(doc, payload, length);
  if (err) return;

  // Caso 1: Es un DELTA (Cambio enviado por la Lambda al crear tarea)
  if (topicStr.equals(AWS_TOPIC_SHADOW_DELTA)) {
    processTasksJson(doc["state"]);
  } 
  // Caso 2: NUEVO EN V4 - Es la respuesta inicial GET/ACCEPTED (Arranque)
  else if (topicStr.equals(AWS_TOPIC_SHADOW_GET_ACCEPTED)) {
    Serial.println("Estado Inicial Recibido.");
    // La estructura de GET/ACCEPTED es {"state": {"desired": ...}}
    processTasksJson(doc["state"]);
  }
}

void reportCurrentStateToShadow() {
  DynamicJsonDocument doc(512); JsonObject r = doc.createNestedObject("state").createNestedObject("reported");
  switch (currentState) {
    case STATE_IDLE: r["mode"] = "idle"; break;
    case STATE_FOCUS: r["mode"] = "focus"; if(!tasks.empty()) r["taskId"] = tasks[selectedTaskIndex].id; break;
    case STATE_BREAK: r["mode"] = "break"; break;
    case STATE_PAUSED: r["mode"] = "paused"; break;
  }
  char b[512]; serializeJson(doc, b); client.publish(AWS_TOPIC_SHADOW_UPDATE, b);
}

void publishTaskComplete(String taskId) {
  DynamicJsonDocument doc(256); doc["taskId"] = taskId; doc["userId"] = "demo_user";
  char b[256]; serializeJson(doc, b); client.publish(AWS_TOPIC_COMPLETE, b);
}