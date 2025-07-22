import 'package:firebase_database/firebase_database.dart';

class SensorRepository {
  final _db = FirebaseDatabase.instance.ref();

String normalize(String s) {
  final withTildesReplaced = s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  return withTildesReplaced.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

Stream<int> getDistanceStream(String gallery, String paintingId) {
  final g = normalize(gallery);
  final p = normalize(paintingId);
  final ref = _db.child('sensor/$g/$p/distancia');

  print('📶 Subscrito a /sensor/$g/$p/distancia');

  return ref.onValue.map((event) {
    print('🟡 Evento onValue: ${event.snapshot.value}');
    final v = event.snapshot.value;
    return (v is int) ? v : int.parse(v.toString());
  });
}
}
