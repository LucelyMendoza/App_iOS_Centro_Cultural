import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class Spo2Gauge extends StatelessWidget {
  final int value;

  const Spo2Gauge({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 70,
            maximum: 100,
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 70,
                endValue: 89,
                color: Colors.red,
                label: 'Crítico',
              ),
              GaugeRange(
                startValue: 90,
                endValue: 94,
                color: Colors.orange,
                label: 'Bajo',
              ),
              GaugeRange(
                startValue: 95,
                endValue: 100,
                color: Colors.green,
                label: 'Normal',
              ),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: value.toDouble(),
                enableAnimation: true,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  '$value%',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                angle: 90,
                positionFactor: 0.5,
              )
            ],
          ),
        ],
      ),
    );
  }
}