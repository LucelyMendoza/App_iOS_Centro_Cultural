const mqtt = require('mqtt');
require('dotenv').config();

const client = mqtt.connect(process.env.MQTT_BROKER_URL, {
  username: process.env.MQTT_USERNAME,
  password: process.env.MQTT_PASSWORD
});

client.on('connect', () => {
  console.log('Conectado al broker MQTT con autenticación');
  client.subscribe('centro_cultural/#');
});

client.on('message', (topic, message) => {
  console.log(`[${topic}]: ${message.toString()}`);
});

module.exports = client;
