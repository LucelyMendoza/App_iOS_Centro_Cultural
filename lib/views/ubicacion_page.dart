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

  // Método para copiar con nuevos valores
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

    // Siempre actualizar para tener datos en tiempo real
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
  Map<DeviceIdentifier, int> rssiActual = {}; // NUEVO: Para mostrar RSSI actual
  double environmentFactor = 2.0;
  static const int TX_POWER = -59;
  final String tuUUID = "b9407f30-f5f8-466e-aff9-25556b57fe6d";
  bool isScanning = false;
  late HybridLocalizationService _hybridService;
  Point3D? posicion3D;
  List<Painting> paintingsNearby = [];

  // TIMERS Y SUBSCRIPTIONS
  StreamSubscription? _subscription;
  StreamSubscription? _firebaseSubscription; // <-- AQUÍ AGREGAR ESTA LÍNEA
  Timer? _updateTimer;
  Timer? _cleanupTimer;
  Timer? _scanRestartTimer;

  // Historial más grande para mejor filtrado
  Map<DeviceIdentifier, List<int>> historialRssi = {};
  Map<DeviceIdentifier, int> rssiFiltrado = {};

  // NUEVO: Variables para tracking en tiempo real
  Map<DeviceIdentifier, DateTime> ultimaActualizacionBeacon = {};
  Map<DeviceIdentifier, double> distanciaAnterior = {};

  final Map<DeviceIdentifier, Offset> coordenadasBeacons = {
    DeviceIdentifier("F5:15:6D:1E:BE:64"): const Offset(0.0, 0.0),
    DeviceIdentifier("C8:FC:FC:6D:94:75"): const Offset(4.0, 0.0),
    DeviceIdentifier("EB:01:6C:5F:23:82"): const Offset(2.0, 3.0),
    DeviceIdentifier("C1:8E:5A:07:E1:85"): const Offset(2.0, 3.0),
  };

  Map<DeviceIdentifier, Offset> beaconsDetectados = {};

  Offset? posicionEstimada;
  DateTime? ultimaActualizacionPosicion;

  void iniciarListenerFirebase() {
    _firebaseSubscription = FirebaseDatabase.instance
        .ref('beacons')
        .onValue
        .listen((event) {
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            // Procesar datos de Firebase si es necesario
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
      "F5:15:6D:1E:BE:64": Point3D(x: 0.0, y: 0.0, z: 2.0),
      "C8:FC:FC:6D:94:75": Point3D(x: 4.0, y: 0.0, z: 2.0),
      "EB:01:6C:5F:23:82": Point3D(x: 2.0, y: 3.0, z: 2.0),
    };

    _hybridService = HybridLocalizationService(
      beaconPositions: beaconPositions3D,
    );
    _hybridService.buildFingerprintDatabase();
  }

  void configurarTimers() {
    // Timer principal - AUMENTAR intervalo para reducir carga
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Era 300ms, ahora 1 segundo
      calcularYActualizarPosicion();
      actualizarUI();
      // SEPARAR el envío a Firebase para reducir llamadas
      if (DateTime.now().millisecondsSinceEpoch % 3000 < 1000) {
        // Cada 3 segundos
        enviarDatosAFirebase();
      }
    });

    // Timer para limpiar beacons antiguos - AUMENTAR intervalo
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Era 5 segundos, ahora 10
      limpiarBeaconsAntiguos();
    });
  }

  void enviarDatosAFirebase() {
    try {
      final now = DateTime.now();

      // Usar batch updates para reducir llamadas a Firebase
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

      // Enviar todos los updates en una sola operación
      if (batchUpdate.isNotEmpty) {
        FirebaseDatabase.instance.ref().update(batchUpdate).catchError((error) {
          print("❌ Error en batch update: $error");
        });
      }

      // Enviar posición si existe
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

  void _enviarBeaconAFirebase(
    DeviceIdentifier id,
    int rssi,
    double distancia,
    DateTime now,
  ) {
    try {
      final beaconId = id.toString().replaceAll(':', '').substring(0, 8);
      final data = {
        'rssi': rssi,
        'distancia': double.parse(distancia.toStringAsFixed(3)),
        'timestamp': now.millisecondsSinceEpoch,
        'timestampISO': now.toIso8601String(),
        'deviceId': id.toString(),
        'txPower': TX_POWER,
        'environmentFactor': environmentFactor,
        'activo': true,
      };

      FirebaseDatabase.instance
          .ref('beacons/$beaconId')
          .set(data)
          .catchError((error) => print("❌ Error Firebase beacon: $error"));
    } catch (e) {
      print("❌ Error enviando beacon: $e");
    }
  }

  // FUNCIÓN OPTIMIZADA PARA POSICIÓN
  void enviarPosicionAFirebaseOptimizado(DateTime now) {
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
          .catchError((error) {
            print("❌ Error Firebase posición: $error");
          });
    } catch (e) {
      print("❌ Error enviando posición: $e");
    }
  }

  void actualizarUI() {
    if (mounted) {
      setState(() {
        // Trigger UI update
      });
    }
  }

  void limpiarBeaconsAntiguos() {
    final now = DateTime.now();
    final timeout = const Duration(seconds: 10); // Aumentar de 5 a 10 segundos
    final beaconsParaEliminar = <DeviceIdentifier>[];

    for (final entry in ultimaActualizacionBeacon.entries) {
      if (now.difference(entry.value) > timeout) {
        beaconsParaEliminar.add(entry.key);
      }
    }

    if (beaconsParaEliminar.isNotEmpty) {
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

  // 7. FUNCIÓN PARA ENVIAR POSICIÓN A FIREBASE
  void enviarPosicionAFirebase() {
    if (posicionEstimada != null) {
      final data = {
        'x': double.parse(posicionEstimada!.dx.toStringAsFixed(3)),
        'y': double.parse(posicionEstimada!.dy.toStringAsFixed(3)),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'timestampISO': DateTime.now().toIso8601String(),
        'beaconsUsados': distanciasBeacons.length,
        'calidad': distanciasBeacons.length >= 3 ? 'buena' : 'regular',
      };

      FirebaseDatabase.instance
          .ref('ubicaciones/usuario1')
          .set(data)
          .catchError((error) {
            print("❌ Error enviando posición a Firebase: $error");
          });
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

    escanearDispositivos();
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

  void escanearDispositivos() async {
    if (isScanning) return;

    setState(() => isScanning = true);

    try {
      await FlutterBluePlus.stopScan();

      // CONFIGURACIÓN MÁS ESTABLE
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 60), // Aumentar timeout
        androidUsesFineLocation: true,
        continuousUpdates: true,
        continuousDivisor: 2, // Reducir frecuencia para mayor estabilidad
      );

      _subscription?.cancel();
      _subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (var result in results) {
            procesarResultadoEscaneo(result);
          }
        },
        onError: (error) {
          print("❌ Error en escaneo: $error");
          // REINICIO MÁS SUAVE
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _reiniciarEscaneo();
          });
        },
      );
    } catch (e) {
      print("❌ Error iniciando escaneo: $e");
      setState(() => isScanning = false);
    }
  }

  void _reiniciarEscaneo() {
    if (mounted) {
      setState(() => isScanning = false);

      // Cancelar timer anterior si existe
      _scanRestartTimer?.cancel();

      // Reiniciar después de un breve delay
      _scanRestartTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) escanearDispositivos();
      });
    }
  }

  void procesarResultadoEscaneo(ScanResult result) {
    final data = result.advertisementData.manufacturerData;

    // Verificar si es un beacon válido
    if (data.isEmpty || data.values.first.length < 23) {
      return;
    }

    final uuidStr = _bytesToUuid(data.values.first.sublist(2, 18));

    // Verificar UUID
    if (uuidStr.toLowerCase() != tuUUID.toLowerCase()) {
      return;
    }

    final id = result.device.id;
    final nuevoRssi = result.rssi;

    // PERMITIR BEACONS DINÁMICOS
    if (!coordenadasBeacons.containsKey(id)) {
      print("🆕 Nuevo beacon detectado: ${id.toString().substring(0, 17)}");

      // Asignar coordenadas temporales (se pueden ajustar dinámicamente)
      beaconsDetectados[id] = Offset(
        Random().nextDouble() * 5.0,
        Random().nextDouble() * 4.0,
      );

      // Inicializar en mapas
      distanciasBeacons[id] = 0.0;
      rssiActual[id] = 0;
      ultimaActualizacionBeacon[id] = DateTime.now();
      distanciaAnterior[id] = 0.0;
    }

    print(
      "📡 Beacon: ${id.toString().substring(0, 17)} - RSSI: $nuevoRssi dBm",
    );

    // Filtrado mejorado de RSSI
    final lista = historialRssi.putIfAbsent(id, () => []);
    lista.add(nuevoRssi);
    if (lista.length > 10) lista.removeAt(0);

    // Calcular RSSI filtrado con promedio móvil ponderado
    int promedioRssi = _calcularRSSIFiltrado(lista);
    final nuevaDistancia = calcularDistancia(promedioRssi);
    final distanciaPrevia = distanciasBeacons[id] ?? 0.0;

    // Actualizar estados
    setState(() {
      rssiFiltrado[id] = promedioRssi;
      rssiActual[id] = promedioRssi;
      distanciasBeacons[id] = nuevaDistancia;
      ultimaActualizacionBeacon[id] = DateTime.now();
      distanciaAnterior[id] = distanciaPrevia;
    });

    // Actualizar provider
    ref
        .read(beaconsProvider.notifier)
        .updateBeacon(id, promedioRssi, nuevaDistancia);

    print("📏 Distancia: ${nuevaDistancia.toStringAsFixed(3)}m");
  }

  int _calcularRSSIFiltrado(List<int> lista) {
    if (lista.isEmpty) return 0;

    // Usar solo los últimos 3 valores para mayor reactividad
    final ultimosValores = lista.length > 3
        ? lista.sublist(lista.length - 3)
        : lista;

    // Promedio simple de los últimos valores
    return (ultimosValores.reduce((a, b) => a + b) ~/ ultimosValores.length);
  }

  void enviarBeaconAFirebaseInmediato(
    DeviceIdentifier id,
    int rssi,
    double distancia,
  ) async {
    try {
      final beaconId = id.toString().replaceAll(':', '').substring(0, 8);
      final now = DateTime.now();

      final data = {
        'rssi': rssi,
        'distancia': double.parse(distancia.toStringAsFixed(3)),
        'timestamp': now.millisecondsSinceEpoch,
        'timestampISO': now.toIso8601String(),
        'deviceId': id.toString(),
        'txPower': TX_POWER,
        'environmentFactor': environmentFactor,
      };

      // Enviar a Firebase SIN await para no bloquear
      FirebaseDatabase.instance
          .ref('beacons/$beaconId')
          .set(data)
          .then((_) {
            print(
              "✅ Firebase actualizado - Beacon $beaconId: ${distancia.toStringAsFixed(3)}m, RSSI: $rssi dBm",
            );
          })
          .catchError((error) {
            print("❌ Error Firebase: $error");
          });
    } catch (e) {
      print("❌ Error enviando a Firebase: $e");
    }
  }

  void calcularYActualizarPosicion() {
    final now = DateTime.now();
    final beaconsActivos = <String, double>{};
    final rssiActivos = <String, int>{};

    for (final entry in distanciasBeacons.entries) {
      final id = entry.key.toString();
      final ultimaActualizacion = ultimaActualizacionBeacon[entry.key];

      // CAMBIAR timeout de 2 a 5 segundos para mayor estabilidad
      if (ultimaActualizacion != null &&
          now.difference(ultimaActualizacion).inSeconds < 5) {
        beaconsActivos[id] = entry.value;
        rssiActivos[id] = rssiActual[entry.key] ?? 0;
      }
    }

    // CAMBIAR de 3 a 2 beacons mínimos para funcionar
    if (beaconsActivos.length >= 2) {
      posicion3D = _hybridService.hybridLocalization(
        beaconsActivos,
        rssiActivos,
      );

      if (posicion3D != null) {
        posicionEstimada = Offset(posicion3D!.x, posicion3D!.y);

        // BUSCAR PINTURAS CERCANAS
        paintingsNearby = _hybridService.getNearbyPaintings(
          posicion3D!,
          radius: 2.0, // Aumentar radio de detección
        );

        if (mounted) {
          setState(() {
            ultimaActualizacionPosicion = DateTime.now();
          });
        }
      }
    }
  }

  void _enviarPosicion3DAFirebase(DateTime now) {
    if (posicion3D == null) return;

    try {
      final data = {
        'x': double.parse(posicion3D!.x.toStringAsFixed(3)),
        'y': double.parse(posicion3D!.y.toStringAsFixed(3)),
        'z': double.parse(posicion3D!.z.toStringAsFixed(3)),
        'timestamp': now.millisecondsSinceEpoch,
        'timestampISO': now.toIso8601String(),
        'beaconsUsados': distanciasBeacons.length,
        'calidad': distanciasBeacons.length >= 3 ? 'buena' : 'regular',
        'paintingsNearby': paintingsNearby.map((p) => p.title).toList(),
        'activo': true,
      };

      FirebaseDatabase.instance
          .ref('ubicaciones/usuario1')
          .set(data)
          .catchError((error) => print("❌ Error Firebase posición 3D: $error"));
    } catch (e) {
      print("❌ Error enviando posición 3D: $e");
    }
  }

  double calcularDistancia(int rssi, {int txPower = TX_POWER}) {
    if (rssi == 0) return -1.0;

    // Fórmula logarítmica mejorada
    final ratio = (txPower - rssi) / (10.0 * environmentFactor);
    double distancia = pow(10, ratio).toDouble();

    // Aplicar corrección empírica
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

  // Enviar cada beacon individual a Firebase
  void enviarBeaconAFirebase(
    DeviceIdentifier id,
    int rssi,
    double distancia,
  ) async {
    try {
      final beaconId = id.toString().replaceAll(':', '').substring(0, 8);
      final now = DateTime.now();

      // Enviar con timestamp más preciso
      await FirebaseDatabase.instance.ref('beacons/$beaconId').set({
        'rssi': rssi,
        'distancia': double.parse(
          distancia.toStringAsFixed(3),
        ), // Precisión de 3 decimales
        'timestamp': now.millisecondsSinceEpoch,
        'timestampISO': now.toIso8601String(),
        'deviceId': id.toString(),
      });

      print(
        "Beacon $beaconId: ${distancia.toStringAsFixed(3)}m, RSSI: $rssi dBm",
      );
    } catch (e) {
      print("Error enviando beacon a Firebase: $e");
    }
  }

  void enviarUbicacionAFirebase(double x, double y) async {
    try {
      await FirebaseDatabase.instance.ref('ubicaciones/usuario1').set({
        'x': x,
        'y': y,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error enviando ubicación a Firebase: $e");
    }
  }

  String _bytesToUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    // Cancelar todas las suscripciones y timers de forma ordenada
    _subscription?.cancel();
    _firebaseSubscription?.cancel();
    _updateTimer?.cancel();
    _cleanupTimer?.cancel();
    _scanRestartTimer?.cancel();

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
              15, // Cambiar de 8 a 15 segundos
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
            onPressed: isScanning ? null : escanearDispositivos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de estado
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
                      ? 'Escaneando... $beaconsActivos beacons activos'
                      : 'Escaneo detenido',
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
          // Información de posición
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
              ),
              child: CustomPaint(
                painter: MapaBeaconsPainter(
                  coordenadasBeacons: {
                    ...coordenadasBeacons,
                    ...beaconsDetectados,
                  },
                  posicionEstimada: posicionEstimada,
                  beaconsData: beaconsData,
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
