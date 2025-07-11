import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  double environmentFactor = 2.0;
  static const int TX_POWER = -59;
  final String tuUUID = "b9407f30-f5f8-466e-aff9-25556b57fe6d";
  bool isScanning = false;
  StreamSubscription? _subscription;
  Timer? _updateTimer;
  Timer? _cleanupTimer;
  Timer? _uiUpdateTimer;

  // Reducir la ventana de promedio para respuesta más rápida
  Map<DeviceIdentifier, List<int>> historialRssi = {};
  Map<DeviceIdentifier, int> rssiFiltrado = {};

  final Map<DeviceIdentifier, Offset> coordenadasBeacons = {
    DeviceIdentifier("F5:15:6D:1E:BE:64"): const Offset(0.0, 0.0),
    DeviceIdentifier("C8:FC:FC:6D:94:75"): const Offset(4.0, 0.0),
    DeviceIdentifier("EB:01:6C:5F:23:82"): const Offset(2.0, 3.0),
  };

  Offset? posicionEstimada;
  DateTime? ultimaActualizacionPosicion;

  @override
  void initState() {
    super.initState();
    // Inicializar distancias
    for (var id in coordenadasBeacons.keys) {
      distanciasBeacons[id] = 0.0;
    }
    iniciarProcesoBluetooth();

    // Timer para actualización de posición más frecuente
    _updateTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      calcularYActualizarPosicion();
    });

    // Timer para limpiar beacons antiguos
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref
          .read(beaconsProvider.notifier)
          .removeOldBeacons(const Duration(seconds: 8));
    });

    // Timer para forzar actualización de UI
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          // Forzar rebuild para mostrar actualizaciones en tiempo real
        });
      }
    });
  }

  Future<void> iniciarProcesoBluetooth() async {
    await solicitarPermisos();
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      print("Bluetooth no soportado");
      return;
    }

    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      print("Bluetooth apagado");
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
      print("Permisos no otorgados");
    }
  }

  void escanearDispositivos() async {
    if (isScanning) return;

    setState(() => isScanning = true);

    try {
      // Escaneo continuo
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: true,
      );

      _subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (var result in results) {
            procesarResultadoEscaneo(result);
          }
        },
        onError: (error) {
          print("Error en escaneo: $error");
          if (mounted) {
            setState(() => isScanning = false);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) escanearDispositivos();
            });
          }
        },
      );

      _subscription?.onDone(() {
        if (mounted) {
          setState(() => isScanning = false);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) escanearDispositivos();
          });
        }
      });
    } catch (e) {
      print("Error iniciando escaneo: $e");
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  void procesarResultadoEscaneo(ScanResult result) {
    final data = result.advertisementData.manufacturerData;
    if (data.isNotEmpty && data.values.first.length >= 23) {
      final uuidStr = _bytesToUuid(data.values.first.sublist(2, 18));
      if (uuidStr.toLowerCase() == tuUUID.toLowerCase()) {
        final id = result.device.id;
        final nuevoRssi = result.rssi;

        // Actualizar el historial de RSSI con ventana más pequeña
        final lista = historialRssi.putIfAbsent(id, () => []);
        lista.add(nuevoRssi);
        if (lista.length > 2) lista.removeAt(0); // Ventana más pequeña

        // Calcular promedio simple para mayor responsividad
        final promedio = lista.reduce((a, b) => a + b) ~/ lista.length;
        final nuevaDistancia = calcularDistancia(promedio);

        // Actualizar provider y estado local inmediatamente
        ref
            .read(beaconsProvider.notifier)
            .updateBeacon(id, promedio, nuevaDistancia);

        setState(() {
          rssiFiltrado[id] = promedio;
          distanciasBeacons[id] = nuevaDistancia;
        });

        // Enviar cada beacon individual a Firebase en tiempo real
        enviarBeaconAFirebase(id, promedio, nuevaDistancia);
      }
    }
  }

  void calcularYActualizarPosicion() {
    if (rssiFiltrado.length >= 3) {
      final beaconsUsados = rssiFiltrado.entries.take(3).toList();
      final posiciones = beaconsUsados
          .map((e) => coordenadasBeacons[e.key])
          .whereType<Offset>()
          .toList();
      final distancias = beaconsUsados
          .map((e) => distanciasBeacons[e.key] ?? 0.0)
          .toList();

      if (posiciones.length == 3) {
        final nuevaPos = trilateracion(
          posiciones[0],
          distancias[0],
          posiciones[1],
          distancias[1],
          posiciones[2],
          distancias[2],
        );

        // Actualizar posición siempre para tiempo real
        setState(() {
          posicionEstimada = nuevaPos;
          ultimaActualizacionPosicion = DateTime.now();
        });

        enviarUbicacionAFirebase(nuevaPos.dx, nuevaPos.dy);
      }
    }
  }

  double calcularDistancia(int rssi, {int txPower = TX_POWER}) {
    if (rssi == 0) return -1.0;

    // Fórmula mejorada para mejor precisión
    final exponente = (txPower - rssi) / (10 * environmentFactor);
    final distancia = pow(10, exponente).toDouble();

    // Aplicar límites razonables
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
    if (denominador.abs() < 0.0001) {
      return posicionEstimada ?? const Offset(2.0, 1.5);
    }

    final x = (C * E - F * B) / denominador;
    final y = (C * D - A * F) / (B * D - A * E);

    return Offset(x.toDouble(), y.toDouble());
  }

  // Enviar cada beacon individual a Firebase
  void enviarBeaconAFirebase(
    DeviceIdentifier id,
    int rssi,
    double distancia,
  ) async {
    try {
      final beaconId = id.toString().replaceAll(':', '').substring(0, 8);
      await FirebaseDatabase.instance.ref('beacons/$beaconId').set({
        'rssi': rssi,
        'distancia': distancia,
        'timestamp': DateTime.now().toIso8601String(),
      });
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
    _subscription?.cancel();
    _updateTimer?.cancel();
    _cleanupTimer?.cancel();
    _uiUpdateTimer?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beaconsData = ref.watch(beaconsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación - iBeacon'),
        backgroundColor: isScanning ? Colors.green : Colors.red,
        actions: [
          IconButton(
            icon: Icon(
              isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
              color: Colors.white,
            ),
            onPressed: isScanning ? null : escanearDispositivos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de estado mejorado
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  )
                else
                  Icon(Icons.bluetooth_disabled, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  isScanning
                      ? 'Escaneando beacons en tiempo real...'
                      : 'Escaneo detenido',
                  style: TextStyle(
                    color: isScanning
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Información de posición mejorada
          if (posicionEstimada != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              margin: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    '📍 Posición estimada:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'X: ${posicionEstimada!.dx.toStringAsFixed(3)}m, Y: ${posicionEstimada!.dy.toStringAsFixed(3)}m',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  if (ultimaActualizacionPosicion != null)
                    Text(
                      'Actualizado: ${DateTime.now().difference(ultimaActualizacionPosicion!).inMilliseconds}ms ago',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),

          // Contador de beacons con animación
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: beaconsData.length >= 3
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: beaconsData.length >= 3 ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  beaconsData.length >= 3 ? Icons.check_circle : Icons.warning,
                  color: beaconsData.length >= 3 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Beacons detectados: ${beaconsData.length}/3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: beaconsData.length >= 3
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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
                  coordenadasBeacons: coordenadasBeacons,
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

          // Lista de beacons con información en tiempo real
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: beaconsData.length,
              itemBuilder: (context, index) {
                final entry = beaconsData.entries.elementAt(index);
                final beacon = entry.value;
                final age = DateTime.now().difference(
                  beacon.ultimaActualizacion,
                );
                final beaconId = entry.key.toString().substring(0, 17);

                // Determinar estado de conexión
                final isActive = age.inSeconds < 5;
                final signalStrength = beacon.rssi > -70
                    ? 'Excelente'
                    : beacon.rssi > -80
                    ? 'Buena'
                    : beacon.rssi > -90
                    ? 'Débil'
                    : 'Muy débil';

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Card(
                    elevation: isActive ? 4 : 1,
                    color: isActive ? Colors.white : Colors.grey.shade100,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.green : Colors.grey,
                        child: Text(
                          '${beacon.distancia.toStringAsFixed(1)}m',
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
                              Icon(
                                Icons.signal_cellular_alt,
                                size: 16,
                                color: beacon.rssi > -70
                                    ? Colors.green
                                    : beacon.rssi > -80
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text('${beacon.rssi} dBm ($signalStrength)'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${beacon.distancia.toStringAsFixed(2)} metros',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actualizado: ${age.inMilliseconds}ms ago',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'ACTIVO' : 'INACTIVO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'n=${environmentFactor.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
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

    // Dibujar grid de fondo
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
