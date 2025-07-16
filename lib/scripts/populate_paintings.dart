import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io'; // Para exit()

void main() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDpXCHbi1i7bpxnG7hyICxRgKXo9z1nY1c",
      appId: "1:176276096987:android:3c45e9057fb6ab85d149fe",
      messagingSenderId: "176276096987",
      projectId: "com.example.mi_app",
    ),
  );

  print('Creando pinturas...');
  await populatePaintings();
  print('✅ ¡Listo!');
  exit(0);
}

Future<void> populatePaintings() async {
  final db = FirebaseFirestore.instance;
  final galleryRef = db
      .collection('galerias')
      .doc('galeria1')
      .collection("pinturas"); // Ya estamos en la colección 'pinturas'

  // Lista de 15 pinturas de ejemplo (p3 a p17)
  final paintings = [
    {
      'title': 'El Jardín de las Delicias',
      'author': 'El Bosco',
      'year': '1490-1500',
      'details': 'Tríptico que representa el paraíso, la tierra y el infierno',
      'imagePath': 'gs://tu-bucket/pinturas/jardin_delicias.jpg',
      'position': {'x': 0.8, 'y': 0.7, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'La Última Cena',
      'author': 'Leonardo da Vinci',
      'year': '1495-1498',
      'details': 'Representación de la última cena de Jesús con sus discípulos',
      'imagePath': 'gs://tu-bucket/pinturas/ultima_cena.jpg',
      'position': {'x': 1.2, 'y': 0.5, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'El Nacimiento de Venus',
      'author': 'Sandro Botticelli',
      'year': '1484-1486',
      'details': 'Venus emergiendo del mar como una mujer adulta',
      'imagePath': 'gs://tu-bucket/pinturas/nacimiento_venus.jpg',
      'position': {'x': 2.0, 'y': 0.8, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'Las Meninas',
      'author': 'Diego Velázquez',
      'year': '1656',
      'details': 'Retrato de la infanta Margarita y su séquito',
      'imagePath': 'gs://tu-bucket/pinturas/meninas.jpg',
      'position': {'x': 2.5, 'y': 1.0, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'La Ronda de Noche',
      'author': 'Rembrandt',
      'year': '1642',
      'details': 'Retrato grupal de la milicia cívica de Ámsterdam',
      'imagePath': 'gs://tu-bucket/pinturas/ronda_noche.jpg',
      'position': {'x': 0.5, 'y': 1.5, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'El Beso',
      'author': 'Gustav Klimt',
      'year': '1907-1908',
      'details': 'Pareja abrazada con vestimentas decorativas doradas',
      'imagePath': 'gs://tu-bucket/pinturas/el_beso.jpg',
      'position': {'x': 1.8, 'y': 1.7, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'Guernica',
      'author': 'Pablo Picasso',
      'year': '1937',
      'details':
          'Representación del bombardeo de Guernica durante la guerra civil española',
      'imagePath': 'gs://tu-bucket/pinturas/guernica.jpg',
      'position': {'x': 2.2, 'y': 2.0, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'La Persistencia de la Memoria',
      'author': 'Salvador Dalí',
      'year': '1931',
      'details': 'Relojes derritiéndose en un paisaje onírico',
      'imagePath': 'gs://tu-bucket/pinturas/relojes_dali.jpg',
      'position': {'x': 0.7, 'y': 2.3, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'El Grito',
      'author': 'Edvard Munch',
      'year': '1893',
      'details': 'Figura andrógina en un momento de angustia existencial',
      'imagePath': 'gs://tu-bucket/pinturas/el_grito.jpg',
      'position': {'x': 1.5, 'y': 2.5, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'La Libertad Guiando al Pueblo',
      'author': 'Eugène Delacroix',
      'year': '1830',
      'details': 'Representación alegórica de la Revolución de Julio',
      'imagePath': 'gs://tu-bucket/pinturas/libertad_guiando.jpg',
      'position': {'x': 2.8, 'y': 0.3, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'Las Tres Gracias',
      'author': 'Rubens',
      'year': '1630-1635',
      'details': 'Representación mitológica de las diosas de la belleza',
      'imagePath': 'gs://tu-bucket/pinturas/tres_gracias.jpg',
      'position': {'x': 0.3, 'y': 1.0, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'La Joven de la Perla',
      'author': 'Johannes Vermeer',
      'year': '1665',
      'details': 'Retrato de una joven con un pendiente de perla',
      'imagePath': 'gs://tu-bucket/pinturas/joven_perla.jpg',
      'position': {'x': 1.0, 'y': 2.0, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'El Juicio Final',
      'author': 'Miguel Ángel',
      'year': '1536-1541',
      'details': 'Fresco que representa el segundo advenimiento de Cristo',
      'imagePath': 'gs://tu-bucket/pinturas/juicio_final.jpg',
      'position': {'x': 2.5, 'y': 1.5, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'Los Girasoles',
      'author': 'Vincent van Gogh',
      'year': '1888',
      'details': 'Serie de cuadros con girasoles en un jarrón',
      'imagePath': 'gs://tu-bucket/pinturas/girasoles.jpg',
      'position': {'x': 0.5, 'y': 2.8, 'z': 1.5},
      'detectionRadius': 0.8,
    },
    {
      'title': 'La Creación de Adán',
      'author': 'Miguel Ángel',
      'year': '1511',
      'details': 'Escena del Génesis donde Dios da vida a Adán',
      'imagePath': 'gs://tu-bucket/pinturas/creacion_adan.jpg',
      'position': {'x': 2.0, 'y': 0.3, 'z': 1.5},
      'detectionRadius': 0.8,
    },
  ];

  // Agregar pinturas a la colección
  final batch = db.batch();
  for (var i = 0; i < paintings.length; i++) {
    final docRef = galleryRef.doc('p${i + 3}'); // p3 a p17
    batch.set(docRef, paintings[i]);
  }

  await batch.commit();
  print('✅ 15 pinturas creadas en galeria1/pinturas (p3 a p17)');
}
