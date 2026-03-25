/*
 * Archivo de secretos
 */

// --- WiFi ---
#define WIFI_SSID ""
#define WIFI_PASSWORD ""

// --- Nombre de dominio/punto de conexión AWS IoT ---
#define AWS_IOT_ENDPOINT ""

// Nombre del "Objeto" (Thing) en AWS IoT
#define THINGNAME ""

// --- Certificados de AWS ---
const char AWS_CERT_CA[] = R"EOF(
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
)EOF";

const char AWS_CERT_CRT[] = R"EOF(
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
)EOF";

const char AWS_CERT_PRIVATE[] = R"EOF(
-----BEGIN RSA PRIVATE KEY-----
-----END RSA PRIVATE KEY-----
)EOF";
