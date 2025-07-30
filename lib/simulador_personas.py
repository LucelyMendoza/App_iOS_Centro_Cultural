import time
import random
import firebase_admin
from firebase_admin import credentials, db

# Inicializa Firebase con tu clave y la URL de tu base de datos
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://beaconlocalization-default-rtdb.firebaseio.com/'
})

# Referencia al nodo sala/personas
ref = db.reference("sala/personas")

# Inicializa el contador si no existe
if ref.get() is None:
    ref.set(0)

# Simula entradas de personas
print("Simulando entradas...")
for i in range(10):
    actual = ref.get()
    nuevo_valor = actual + random.randint(1, 2)
    ref.set(nuevo_valor)
    print(f"Entrada simulada #{i + 1}: Total personas = {nuevo_valor}")
    time.sleep(3)  # Espera 3 segundos antes de la siguiente simulación
