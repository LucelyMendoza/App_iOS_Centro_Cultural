const express = require('express');
const cors = require('cors');
require('dotenv').config();

const mqttClient = require('./mqtt/client');
const authRoutes = require('./routes/auth');
const mqttRoutes = require('./routes/mqtt');


const app = express();
app.use(cors());
app.use(express.json());
app.use('/api/mqtt', mqttRoutes);
app.use('/api/auth', authRoutes);

app.get('/', (req, res) => {
  res.send('Backend activo');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});

