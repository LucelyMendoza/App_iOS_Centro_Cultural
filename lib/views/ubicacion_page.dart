import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hybrid_localization_service.dart';
import '../models/point3d.dart';
import '../models/painting.dart';

class UbicacionPage extends ConsumerStatefulWidget {
  const UbicacionPage({super.key});

  @override
  ConsumerState<UbicacionPage> createState() => _UbicacionPageState();
}

final beaconsProvider =
    StateNotifierProvider<BeaconsNotifier, Map<DeviceIdentifier, BeaconData>>((
      ref,
    ) {
      return BeaconsNotifier();
    });

class BeaconData {
  final int rssi;
  final double distancia;
  final DateTime ultimaActualizacion;

  BeaconData({
    required this.rssi,
    required this.distancia,
    required this.ultimaActualizacion,
  });

  BeaconData copyWith({
    int? rssi,
    double? distancia,
    DateTime? ultimaActualizacion,
  }) {
    return BeaconData(
      rssi: rssi ?? this.rssi,
      distancia: distancia ?? this.distancia,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}

class BeaconsNotifier extends StateNotifier<Map<DeviceIdentifier, BeaconData>> {
  BeaconsNotifier() : super({});

  void updateBeacon(DeviceIdentifier id, int rssi, double distancia) {
    final now = DateTime.now();

    state = {
      ...state,
      id: BeaconData(
        rssi: rssi,
        distancia: distancia,
        ultimaActualizacion: now,
      ),
    };
  }

  void removeOldBeacons(Duration timeout) {
    final now = DateTime.now();
    final newState = <DeviceIdentifier, BeaconData>{};

    for (final entry in state.entries) {
      if (now.difference(entry.value.ultimaActualizacion) <= timeout) {
        newState[entry.key] = entry.value;
      }
    }

    if (newState.length != state.length) {
      state = newState;
    }
  }
}

class _UbicacionPageState extends ConsumerState<UbicacionPage> {
  Map<DeviceIdentifier, double> distanciasBeacons = {};
  Map<DeviceIdentifier, int> rssiActual = {};
  double environmentFactor = 2.0;
  static const int TX_POWER = -59;
  final String tuUUID = "b9407f30-f5f8-466e-aff9-25556b57fe6d";
  bool isScanning = false;
  bool _disposed = false;
  late HybridLocalizationService _hybridService;
  Point3D? posicion3D;
  List<Painting> paintingsNearby = [];

  // TIMERS Y SUBSCRIPTIONS
  StreamSubscription? _subscription;
  StreamSubscription? _firebaseSubscription;
  Timer? _updateTimer;
  Timer? _cleanupTimer;
  Timer? _scanRestartTimer; // Agregado el timer que faltaba

  // Historial para filtrado
  Map<DeviceIdentifier, List<int>> historialRssi = {};
  Map<DeviceIdentifier, int> rssiFiltrado = {};

  // Variables para tracking en tiempo real
  Map<DeviceIdentifier, DateTime> ultimaActualizacionBeacon = {};
  Map<DeviceIdentifier, double> distanciaAnterior = {};

  final Map<DeviceIdentifier, Offset> coordenadasBeacons = {
    // Beacon 1: Esquina inferior izquierda
    DeviceIdentifier("EC:02:6D:60:24:83"): const Offset(0.0, 0.0),
    // Beacon 2: Esquina inferior derecha
    DeviceIdentifier("F6:16:6E:1F:BF:65"): const Offset(3.0, 0.0),
    // Beacon 3: Esquina superior centro
    DeviceIdentifier("EB:01:6C:5F:23:82"): const Offset(1.5, 3.0),
    // Beacon 4: Centro de la sala (si tienes un cuarto beacon)
    DeviceIdentifier("E8:FE:69:5C:20:7F"): const Offset(1.5, 1.5),
  };

  Offset? posicionEstimada;
  DateTime? ultimaActualizacionPosicion;

  void iniciarListenerFirebase() {
    _firebaseSubscription = FirebaseDatabase.instance
        .ref('beacons')
        .onValue
        .listen((event) {
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            print("Datos de Firebase actualizados: ${data.length} beacons");
          }
        });
  }

  @override
  void initState() {
    super.initState();
    _initializeHybridService();
    inicializarMapas();
    iniciarProcesoBluetooth();
    configurarTimers();
  }

  void inicializarMapas() {
    for (var id in coordenadasBeacons.keys) {
      distanciasBeacons[id] = 0.0;
      rssiActual[id] = 0;
      ultimaActualizacionBeacon[id] = DateTime.now();
      distanciaAnterior[id] = 0.0;
    }
  }

  void _initializeHybridService() {
    final beaconPositions3D = {
      // Coordenadas 3D reales de la sala (3m x 3m x 3m de altura)
      "EC:02:6D:60:24:83": Point3D(x: 0.0, y: 0.0, z: 2.0), // Esquina 1
      "F6:16:6E:1F:BF:65": Point3D(x: 3.0, y: 0.0, z: 2.0), // Esquina 2
      "EB:01:6C:5F:23:82": Point3D(x: 1.5, y: 3.0, z: 2.0), // Esquina 3
      "E8:FE:69:5C:20:7F": Point3D(x: 1.5, y: 1.5, z: 2.0), // Centro
    };

    _hybridService = HybridLocalizationService(
      beaconPositions: beaconPositions3D,
    );
    _hybridService.buildFingerprintDatabase();
  }

  void configurarTimers() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      calcularYActualizarPosicion();
      actualizarUI();
      if (DateTime.now().millisecondsSinceEpoch % 3000 < 1000) {
        enviarDatosAFirebase();
      }
    });

    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_disposed) return;
      limpiarBeaconsAntiguos();
    });
  }

  void enviarDatosAFirebase() {
    if (_disposed) return;

    try {
      final now = DateTime.now();
      final batchUpdate = <String, dynamic>{};

      for (final entry in distanciasBeacons.entries) {
        final id = entry.key;
        final ultimaActualizacion = ultimaActualizacionBeacon[id];

        if (ultimaActualizacion != null &&
            now.difference(ultimaActualizacion).inSeconds < 5) {
          final beaconId = id.toString().replaceAll(':', '').substring(0, 8);
          batchUpdate['beacons/$beaconId'] = {
            'rssi': rssiActual[id] ?? 0,
            'distancia': double.parse(entry.value.toStringAsFixed(3)),
            'timestamp': now.millisecondsSinceEpoch,
            'timestampISO': now.toIso8601String(),
            'deviceId': id.toString(),
            'txPower': TX_POWER,
            'environmentFactor': environmentFactor,
            'activo': true,
          };
        }
      }

      if (batchUpdate.isNotEmpty) {
        FirebaseDatabase.instance.ref().update(batchUpdate).catchError((error) {
          print("❌ Error en batch update: $error");
        });
      }

      if (posicionEstimada != null) {
        _enviarPosicionAFirebase(now);
      }
    } catch (e) {
      print("❌ Error crítico en enviarDatosAFirebase: $e");
    }
  }

  void _enviarPosicionAFirebase(DateTime now) {
    try {
      final data = {
        'x': double.parse(posicionEstimada!.dx.toStringAsFixed(3)),
        'y': double.parse(posicionEstimada!.dy.toStringAsFixed(3)),
        'timestamp': now.millisecondsSinceEpoch,
        'timestampISO': now.toIso8601String(),
        'beaconsUsados': distanciasBeacons.length,
        'calidad': distanciasBeacons.length >= 3 ? 'buena' : 'regular',
        'activo': true,
      };

      FirebaseDatabase.instance
          .ref('ubicaciones/usuario1')
          .set(data)
          .catchError((error) => print("❌ Error Firebase posición: $error"));
    } catch (e) {
      print("❌ Error enviando posición: $e");
    }
  }

  void actualizarUI() {
    if (mounted && !_disposed) {
      setState(() {
        // Trigger UI update
      });
    }
  }

  void limpiarBeaconsAntiguos() {
    if (_disposed) return;

    final now = DateTime.now();
    final timeout = const Duration(seconds: 10);
    final beaconsParaEliminar = <DeviceIdentifier>[];

    for (final entry in ultimaActualizacionBeacon.entries) {
      if (now.difference(entry.value) > timeout) {
        beaconsParaEliminar.add(entry.key);
      }
    }

    if (beaconsParaEliminar.isNotEmpty) {
      if (mounted) {
        setState(() {
          for (final id in beaconsParaEliminar) {
            _marcarBeaconComoInactivo(id);
            distanciasBeacons.remove(id);
            rssiActual.remove(id);
            ultimaActualizacionBeacon.remove(id);
            distanciaAnterior.remove(id);
            historialRssi.remove(id);
            rssiFiltrado.remove(id);
          }
        });
      }

      ref.read(beaconsProvider.notifier).removeOldBeacons(timeout);
    }
  }

  void _marcarBeaconComoInactivo(DeviceIdentifier id) async {
    try {
      final beaconId = id.toString().replaceAll(':', '').substring(0, 8);
      await FirebaseDatabase.instance
          .ref('beacons/$beaconId/activo')
          .set(false);
    } catch (e) {
      print("❌ Error marcando beacon como inactivo: $e");
    }
  }

  Future<void> iniciarProcesoBluetooth() async {
    await solicitarPermisos();

    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      print("❌ Bluetooth no soportado");
      return;
    }

    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      print("❌ Bluetooth apagado");
      return;
    }

    iniciarEscaneoConstante();
  }

  Future<void> solicitarPermisos() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses.values.any((s) => s != PermissionStatus.granted)) {
      print("⚠️ Permisos no otorgados completamente");
    }
  }

  void iniciarEscaneoConstante() async {
    if (isScanning || _disposed) return;

    setState(() => isScanning = true);

    try {
      await FlutterBluePlus.stopScan();

      await FlutterBluePlus.startScan(
        androidUsesFineLocation: true,
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      print("🔄 Escaneo constante iniciado sin límite de tiempo");

      _subscription?.cancel();
      _subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          if (_disposed) return;

          for (var result in results) {
            procesarResultadoEscaneo(result);
          }
        },
        onError: (error) {
          print("❌ Error en escaneo: $error");
          if (!_disposed) {
            _reiniciarEscaneoSuave();
          }
        },
        onDone: () {
          print("⚠️ Stream de escaneo terminado");
          if (!_disposed) {
            _reiniciarEscaneoSuave();
          }
        },
      );

      _monitorearEstadoEscaneo();
    } catch (e) {
      print("❌ Error iniciando escaneo constante: $e");
      setState(() => isScanning = false);

      if (!_disposed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!_disposed) iniciarEscaneoConstante();
        });
      }
    }
  }

  void _reiniciarEscaneoSuave() {
    if (_disposed) return;

    print("🔄 Reiniciando escaneo suavemente...");

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_disposed && mounted) {
        setState(() => isScanning = false);
        iniciarEscaneoConstante();
      }
    });
  }

  void _monitorearEstadoEscaneo() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      // Corregido: isScanningNow es un getter, no un Future
      if (!FlutterBluePlus.isScanningNow && !_disposed) {
        print("⚠️ Escaneo detenido inesperadamente, reiniciando...");
        iniciarEscaneoConstante();
      }
    });
  }

  // UNA SOLA IMPLEMENTACIÓN de procesarResultadoEscaneo
  void procesarResultadoEscaneo(ScanResult result) {
    if (_disposed) return;

    final data = result.advertisementData.manufacturerData;
    if (data.isEmpty || data.values.first.length < 23) return;

    final uuidStr = _bytesToUuid(data.values.first.sublist(2, 18));
    if (uuidStr.toLowerCase() != tuUUID.toLowerCase()) return;

    final id = result.device.id;
    final nuevoRssi = result.rssi;

    /*
    if (!coordenadasBeacons.containsKey(id)) {
      print("🆕 Nuevo beacon detectado: ${id.toString().substring(0, 17)}");
      beaconsDetectados[id] = Offset(
        Random().nextDouble() * 5.0,
        Random().nextDouble() * 4.0,
      );
      // ... resto del código dinámico
    }
    */

    print(
      "📡 Beacon: ${id.toString().substring(0, 17)} - RSSI: $nuevoRssi dBm",
    );

    // Filtrado de RSSI
    final lista = historialRssi.putIfAbsent(id, () => []);
    lista.add(nuevoRssi);
    if (lista.length > 10) lista.removeAt(0);

    int promedioRssi = _calcularRSSIFiltrado(lista);
    final nuevaDistancia = calcularDistancia(promedioRssi);
    final distanciaPrevia = distanciasBeacons[id] ?? 0.0;

    if (mounted) {
      setState(() {
        rssiFiltrado[id] = promedioRssi;
        rssiActual[id] = promedioRssi;
        distanciasBeacons[id] = nuevaDistancia;
        ultimaActualizacionBeacon[id] = DateTime.now();
        distanciaAnterior[id] = distanciaPrevia;
      });
    }

    ref
        .read(beaconsProvider.notifier)
        .updateBeacon(id, promedioRssi, nuevaDistancia);

    print("📏 Distancia: ${nuevaDistancia.toStringAsFixed(3)}m");

    if (!coordenadasBeacons.containsKey(id)) {
      print(
        "⚠️ Beacon desconocido ignorado: ${id.toString().substring(0, 17)}",
      );
      return; // Salir si no es un beacon conocido
    }

    // Continuar con el procesamiento normal para beacons conocidos
    print(
      "📡 Beacon conocido: ${id.toString().substring(0, 17)} - RSSI: $nuevoRssi dBm",
    );
  }

  int _calcularRSSIFiltrado(List<int> lista) {
    if (lista.isEmpty) return 0;

    final ultimosValores = lista.length > 3
        ? lista.sublist(lista.length - 3)
        : lista;

    return (ultimosValores.reduce((a, b) => a + b) ~/ ultimosValores.length);
  }

  void calcularYActualizarPosicion() {
    if (_disposed) return;

    final now = DateTime.now();
    final beaconsActivos = <String, double>{};
    final rssiActivos = <String, int>{};

    // Recopilar solo beacons activos y conocidos
    for (final entry in distanciasBeacons.entries) {
      // ✅ VERIFICAR que el beacon esté en coordenadasBeacons
      if (!coordenadasBeacons.containsKey(entry.key)) continue;

      final id = entry.key.toString();
      final ultimaActualizacion = ultimaActualizacionBeacon[entry.key];

      if (ultimaActualizacion != null &&
          now.difference(ultimaActualizacion).inSeconds < 3) {
        beaconsActivos[id] = entry.value;
        rssiActivos[id] = rssiActual[entry.key] ?? 0;
      }
    }

    if (beaconsActivos.length >= 2) {
      try {
        posicion3D = _hybridService.hybridLocalization(
          beaconsActivos,
          rssiActivos,
        );

        if (posicion3D != null) {
          // ✅ AJUSTAR la altura del usuario (celular a 1.5m típicamente)
          posicion3D = Point3D(
            x: posicion3D!.x,
            y: posicion3D!.y,
            z: 1.5, // Altura fija del usuario con celular
          );

          print(
            "📍 Posición 3D usuario: (${posicion3D!.x.toStringAsFixed(2)}, ${posicion3D!.y.toStringAsFixed(2)}, ${posicion3D!.z.toStringAsFixed(2)})",
          );

          // ✅ LIMITAR la posición del usuario dentro de la sala 3x3m
          final posicionLimitada = Point3D(
            x: posicion3D!.x.clamp(0.0, 3.0),
            y: posicion3D!.y.clamp(0.0, 3.0),
            z: 1.5,
          );

          posicion3D = posicionLimitada;
          posicionEstimada = Offset(posicion3D!.x, posicion3D!.y);

          // Buscar pinturas cercanas con diferentes radios
          final radios = [0.5, 1.0, 1.5, 2.0];
          for (final radius in radios) {
            final paintingsEnRadio = _hybridService.getNearbyPaintings(
              posicion3D!,
              radius: radius,
            );

            if (paintingsEnRadio.isNotEmpty) {
              paintingsNearby = paintingsEnRadio;
              break;
            }
          }

          if (mounted) {
            setState(() {
              ultimaActualizacionPosicion = DateTime.now();
            });
          }
        }
      } catch (e) {
        print("❌ Error en localización híbrida: $e");
      }
    }
  }

  double calcularDistancia(int rssi, {int txPower = TX_POWER}) {
    if (rssi == 0) return -1.0;

    final ratio = (txPower - rssi) / (10.0 * environmentFactor);
    double distancia = pow(10, ratio).toDouble();

    if (distancia < 1.0) {
      distancia = distancia * 0.8;
    } else if (distancia > 10.0) {
      distancia = distancia * 1.2;
    }

    return distancia.clamp(0.1, 50.0);
  }

  Offset trilateracion(
    Offset p1,
    double d1,
    Offset p2,
    double d2,
    Offset p3,
    double d3,
  ) {
    try {
      final A = 2 * (p2.dx - p1.dx);
      final B = 2 * (p2.dy - p1.dy);
      final C =
          pow(d1, 2) -
          pow(d2, 2) -
          pow(p1.dx, 2) +
          pow(p2.dx, 2) -
          pow(p1.dy, 2) +
          pow(p2.dy, 2);
      final D = 2 * (p3.dx - p2.dx);
      final E = 2 * (p3.dy - p2.dy);
      final F =
          pow(d2, 2) -
          pow(d3, 2) -
          pow(p2.dx, 2) +
          pow(p3.dx, 2) -
          pow(p2.dy, 2) +
          pow(p3.dy, 2);

      final denominador = (E * A - B * D);
      if (denominador.abs() < 0.001) {
        return posicionEstimada ?? const Offset(2.0, 1.5);
      }

      final x = (C * E - F * B) / denominador;
      final y = (A * F - C * D) / denominador;

      final resultado = Offset(x.toDouble(), y.toDouble());
      final xLimitado = resultado.dx.clamp(-1.0, 6.0);
      final yLimitado = resultado.dy.clamp(-1.0, 5.0);

      return Offset(xLimitado, yLimitado);
    } catch (e) {
      print("❌ Error en trilateración: $e");
      return posicionEstimada ?? const Offset(2.0, 1.5);
    }
  }

  String _bytesToUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _disposed = true;

    _subscription?.cancel();
    _firebaseSubscription?.cancel();
    _updateTimer?.cancel();
    _cleanupTimer?.cancel();
    _scanRestartTimer?.cancel(); // Cancelar el timer agregado

    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      print("⚠️ Error al detener escaneo: $e");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beaconsData = ref.watch(beaconsProvider);
    final beaconsActivos = beaconsData.values
        .where(
          (beacon) =>
              DateTime.now().difference(beacon.ultimaActualizacion).inSeconds <
              15,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ubicación - $beaconsActivos/${beaconsData.length} Beacons',
        ),
        backgroundColor: isScanning ? Colors.green : Colors.red,
        actions: [
          IconButton(
            icon: Icon(
              isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              color: Colors.white,
            ),
            onPressed: isScanning ? null : iniciarEscaneoConstante,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            color: isScanning ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.bluetooth_disabled, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  isScanning
                      ? 'Escaneo CONSTANTE - $beaconsActivos beacons activos'
                      : 'Escaneo detenido - Toca para reiniciar',
                  style: TextStyle(
                    color: isScanning
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (paintingsNearby.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.palette, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Obras de Arte Cercanas (${paintingsNearby.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...paintingsNearby.map(
                    (painting) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.art_track, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  painting.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${painting.author} (${painting.year})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (posicionEstimada != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '📍 Posición Estimada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'X: ${posicionEstimada!.dx.toStringAsFixed(3)}m\nY: ${posicionEstimada!.dy.toStringAsFixed(3)}m',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última actualización: ${ultimaActualizacionPosicion != null ? "${DateTime.now().difference(ultimaActualizacionPosicion!).inMilliseconds}ms" : "nunca"}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Mapa visual
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.green.shade50],
                ),
              ),
              child: CustomPaint(
                painter: MapaBeacons3DPainter(
                  coordenadasBeacons: coordenadasBeacons, // Solo beacons fijos
                  posicionEstimada: posicionEstimada,
                  posicion3D: posicion3D, // Agregar posición 3D
                  beaconsData: beaconsData,
                  paintingsNearby: paintingsNearby, // Mostrar pinturas
                  config: BeaconConfig(
                    environmentFactor: environmentFactor,
                    txPower: TX_POWER,
                  ),
                ),
                child: Container(),
              ),
            ),
          ),

          // Lista de beacons
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: beaconsData.length,
              itemBuilder: (context, index) {
                final entry = beaconsData.entries.elementAt(index);
                final beacon = entry.value;
                final id = entry.key;
                final beaconId = id.toString().substring(0, 17);

                final age = DateTime.now().difference(
                  beacon.ultimaActualizacion,
                );
                final isActive = age.inSeconds < 8;

                final distanciaActual = distanciasBeacons[id] ?? 0.0;
                final rssiActualValue = rssiActual[id] ?? beacon.rssi;
                final distanciaPrevia = distanciaAnterior[id] ?? 0.0;
                final cambioDistancia = distanciaActual - distanciaPrevia;

                String movimiento = "";
                Color colorMovimiento = Colors.grey;
                if (cambioDistancia.abs() > 0.1) {
                  if (cambioDistancia > 0) {
                    movimiento = "↗️ Alejándose";
                    colorMovimiento = Colors.red;
                  } else {
                    movimiento = "↘️ Acercándose";
                    colorMovimiento = Colors.green;
                  }
                } else {
                  movimiento = "➡️ Estable";
                  colorMovimiento = Colors.blue;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: isActive ? 4 : 1,
                  color: isActive ? Colors.white : Colors.grey.shade100,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.green : Colors.grey,
                      child: Text(
                        '${distanciaActual.toStringAsFixed(1)}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      'Beacon ${beaconId}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.signal_cellular_alt,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text('RSSI: ${rssiActualValue} dBm'),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Distancia: ${distanciaActual.toStringAsFixed(3)}m',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14,
                              color: colorMovimiento,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movimiento,
                              style: TextStyle(
                                color: colorMovimiento,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Actualizado: ${age.inMilliseconds}ms',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'ACTIVO' : 'PERDIDO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MapaBeacons3DPainter extends CustomPainter {
  final Map<DeviceIdentifier, Offset> coordenadasBeacons;
  final Offset? posicionEstimada;
  final Point3D? posicion3D;
  final Map<DeviceIdentifier, BeaconData> beaconsData;
  final List<Painting> paintingsNearby;
  final BeaconConfig config;

  MapaBeacons3DPainter({
    required this.coordenadasBeacons,
    this.posicionEstimada,
    this.posicion3D,
    required this.beaconsData,
    required this.paintingsNearby,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Escala para sala de 3x3 metros
    final scaleX = size.width / 3.5; // Un poco más de espacio
    final scaleY = size.height / 3.5;

    _drawRoom3D(canvas, size, scaleX, scaleY);
    _drawBeacons3D(canvas, size, scaleX, scaleY);
    _drawPaintings3D(canvas, size, scaleX, scaleY);
    _drawUser3D(canvas, size, scaleX, scaleY);
  }

  void _drawRoom3D(Canvas canvas, Size size, double scaleX, double scaleY) {
    // Dibujar piso con perspectiva
    final floorPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final floorPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..close();

    canvas.drawPath(floorPath, floorPaint);

    // Dibujar paredes
    final wallPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    // Pared izquierda
    final leftWallPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..close();

    canvas.drawPath(leftWallPath, wallPaint);

    // Pared derecha
    final rightWallPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..close();

    canvas.drawPath(rightWallPath, wallPaint);

    // Grid del piso
    final gridPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final x = i * scaleX;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.width * 0.2, size.height * 0.8),
        gridPaint,
      );
    }
  }

  void _drawBeacons3D(Canvas canvas, Size size, double scaleX, double scaleY) {
    final beaconPaint = Paint()..color = Colors.blue.shade600;
    final beaconInactivePaint = Paint()..color = Colors.grey.shade400;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final entry in coordenadasBeacons.entries) {
      final beaconData = beaconsData[entry.key];
      final isActive =
          beaconData != null &&
          DateTime.now().difference(beaconData.ultimaActualizacion).inSeconds <
              5;

      // Posición 3D del beacon (fijo en altura 2m)
      final beaconX = entry.value.dx * scaleX;
      final beaconY = size.height - entry.value.dy * scaleY;

      // Efecto 3D - beacon en la pared a 2m de altura
      final beacon3DX = beaconX + (beaconX * 0.1);
      final beacon3DY = beaconY - (2.0 * scaleY * 0.3); // Altura 2m

      // Dibujar beacon con efecto 3D
      canvas.drawCircle(
        Offset(beacon3DX, beacon3DY),
        isActive ? 15 : 10,
        isActive ? beaconPaint : beaconInactivePaint,
      );

      // Highlight central
      canvas.drawCircle(
        Offset(beacon3DX, beacon3DY),
        isActive ? 8 : 5,
        Paint()..color = Colors.white,
      );

      // Rango de detección
      if (isActive && beaconData != null) {
        final rangePaint = Paint()
          ..color = Colors.blue.withOpacity(0.2)
          ..style = PaintingStyle.fill;

        final rangeRadius = beaconData.distancia * min(scaleX, scaleY) * 0.8;
        canvas.drawCircle(Offset(beaconX, beaconY), rangeRadius, rangePaint);
      }

      // Etiqueta del beacon
      final beaconId = entry.key.toString().substring(0, 8);
      final distanciaText = beaconData?.distancia.toStringAsFixed(1) ?? "?";

      textPainter.text = TextSpan(
        text: '$beaconId\n${distanciaText}m',
        style: TextStyle(
          color: isActive ? Colors.blue.shade800 : Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(beacon3DX + 20, beacon3DY - 15));
    }
  }

  void _drawPaintings3D(
    Canvas canvas,
    Size size,
    double scaleX,
    double scaleY,
  ) {
    final paintingPaint = Paint()..color = Colors.orange.shade600;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final painting in paintingsNearby) {
      // Verificar si position no es null antes de acceder a sus propiedades
      if (painting.position == null) continue;

      final paintingX = painting.position!.x * scaleX;
      final paintingY = size.height - painting.position!.y * scaleY;

      // Pintura en la pared a 1.5m de altura
      final painting3DX = paintingX + (paintingX * 0.1);
      final painting3DY = paintingY - (1.5 * scaleY * 0.3);

      // Dibujar marco de pintura
      final frameRect = Rect.fromCenter(
        center: Offset(painting3DX, painting3DY),
        width: 20,
        height: 15,
      );

      canvas.drawRect(frameRect, paintingPaint);
      canvas.drawRect(
        frameRect.deflate(2),
        Paint()..color = Colors.orange.shade200,
      );

      // Etiqueta de la pintura
      textPainter.text = TextSpan(
        text: painting.title,
        style: TextStyle(
          color: Colors.orange.shade800,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(painting3DX + 25, painting3DY - 10));
    }
  }

  void _drawUser3D(Canvas canvas, Size size, double scaleX, double scaleY) {
    if (posicionEstimada == null || posicion3D == null) return;

    final userPaint = Paint()..color = Colors.red.shade600;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Posición del usuario en el piso
    final userX = posicionEstimada!.dx * scaleX;
    final userY = size.height - posicionEstimada!.dy * scaleY;

    // Usuario en el piso a 1.5m de altura (celular)
    final user3DX = userX + (userX * 0.05);
    final user3DY = userY - (1.5 * scaleY * 0.2);

    // Dibujar usuario con animación pulsante
    canvas.drawCircle(Offset(user3DX, user3DY), 20, userPaint);
    canvas.drawCircle(
      Offset(user3DX, user3DY),
      15,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(Offset(user3DX, user3DY), 10, userPaint);

    // Sombra en el piso
    canvas.drawCircle(
      Offset(userX, userY),
      12,
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Fix for the null safety issue - use null-aware operator
    final posicion3DActual =
        posicion3D!; // Safe because we already checked for null above

    // Etiqueta del usuario
    textPainter.text = TextSpan(
      text:
          'TÚ\n(${posicion3DActual.x.toStringAsFixed(1)}, ${posicion3DActual.y.toStringAsFixed(1)}, ${posicion3DActual.z.toStringAsFixed(1)})',
      style: const TextStyle(
        color: Colors.red,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(user3DX + 25, user3DY - 20));
  }

  @override
  bool shouldRepaint(MapaBeacons3DPainter oldDelegate) {
    return oldDelegate.posicionEstimada != posicionEstimada ||
        oldDelegate.beaconsData != beaconsData ||
        oldDelegate.paintingsNearby != paintingsNearby;
  }
}

class BeaconConfig {
  final double environmentFactor;
  final int txPower;

  const BeaconConfig({this.environmentFactor = 2.0, this.txPower = -59});
}

class MapaBeaconsPainter extends CustomPainter {
  final Map<DeviceIdentifier, Offset> coordenadasBeacons;
  final Offset? posicionEstimada;
  final Map<DeviceIdentifier, BeaconData> beaconsData;
  final BeaconConfig config;

  MapaBeaconsPainter({
    required this.coordenadasBeacons,
    this.posicionEstimada,
    required this.beaconsData,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBeacon = Paint()..color = Colors.blue;
    final paintBeaconInactive = Paint()..color = Colors.grey;
    final paintBeaconNuevo = Paint()..color = Colors.orange;
    final paintUsuario = Paint()..color = Colors.red;
    final paintDistance = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paintDistanceFill = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final scaleX = size.width / 8;
    final scaleY = size.height / 8;

    if (scaleX.isNaN || scaleY.isNaN || scaleX <= 0 || scaleY <= 0) {
      return;
    }

    // Dibujar grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (int i = 0; i <= 8; i++) {
      final x = i * scaleX;
      final y = i * scaleY;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final entry in coordenadasBeacons.entries) {
      final p = Offset(
        entry.value.dx * scaleX,
        size.height - entry.value.dy * scaleY,
      );

      final beaconData = beaconsData[entry.key];
      final isActive =
          beaconData != null &&
          DateTime.now().difference(beaconData.ultimaActualizacion).inSeconds <
              5;

      // Dibujar círculo de distancia con animación
      if (isActive && beaconData != null) {
        final radius = beaconData.distancia * min(scaleX, scaleY);
        canvas.drawCircle(p, radius, paintDistanceFill);
        canvas.drawCircle(p, radius, paintDistance);
      }

      // Dibujar beacon con diferentes tamaños según actividad
      canvas.drawCircle(
        p,
        isActive ? 12 : 8,
        isActive ? paintBeacon : paintBeaconInactive,
      );
      canvas.drawCircle(p, isActive ? 8 : 4, Paint()..color = Colors.white);

      // Dibujar texto con información actualizada
      final distanciaText = beaconData?.distancia.toStringAsFixed(2) ?? "?";
      final rssiText = beaconData?.rssi.toString() ?? "?";
      final beaconId = entry.key.toString().substring(0, 8);

      textPainter.text = TextSpan(
        text: '$beaconId\n${distanciaText}m\n${rssiText}dBm',
        style: TextStyle(
          color: isActive ? Colors.black : Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, p + const Offset(15, -30));
    }

    // Dibujar posición estimada con animación
    if (posicionEstimada != null) {
      final p = Offset(
        posicionEstimada!.dx * scaleX,
        size.height - posicionEstimada!.dy * scaleY,
      );

      // Dibujar círculo pulsante
      canvas.drawCircle(p, 16, paintUsuario);
      canvas.drawCircle(p, 12, Paint()..color = Colors.white);
      canvas.drawCircle(p, 8, paintUsuario);

      textPainter.text = TextSpan(
        text:
            'TÚ\n(${posicionEstimada!.dx.toStringAsFixed(2)}, ${posicionEstimada!.dy.toStringAsFixed(2)})',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, p + const Offset(20, -15));
    }
  }

  @override
  bool shouldRepaint(MapaBeaconsPainter oldDelegate) {
    return true; // Siempre repintar para animaciones en tiempo real
  }
}
