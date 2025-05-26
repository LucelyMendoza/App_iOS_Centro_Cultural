const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const usersPath = path.join(__dirname, '../users/users.json');

function getUsers() {
  return JSON.parse(fs.readFileSync(usersPath));
}

exports.register = async (req, res) => {
  const { username, password } = req.body;
  const users = getUsers();

  if (users.find(u => u.username === username))
    return res.status(400).json({ message: 'Usuario ya existe' });

  const hash = await bcrypt.hash(password, 10);
  users.push({ username, password: hash });
  fs.writeFileSync(usersPath, JSON.stringify(users));

  res.json({ message: 'Usuario registrado' });
};

exports.login = async (req, res) => {
  const { username, password } = req.body;
  const users = getUsers();
  const user = users.find(u => u.username === username);

  if (!user || !(await bcrypt.compare(password, user.password)))
    return res.status(401).json({ message: 'Credenciales inválidas' });

  const token = jwt.sign({ username }, process.env.JWT_SECRET, { expiresIn: '1h' });
  res.json({ token });
};

