const express = require('express');
const router = express.Router();
const mqttClient = require('../mqtt/client');

router.post('/publish', (req, res) => {
  const { topic, message } = req.body;

  if (!topic || !message) {
    return res.status(400).json({ error: 'Faltan datos' });
  }

  mqttClient.publish(topic, message, {}, (err) => {
    if (err) {
      console.error('Error al publicar:', err);
      return res.status(500).json({ error: 'No se pudo publicar' });
    }

    res.json({ status: 'Mensaje publicado con éxito' });
  });
});

module.exports = router;
