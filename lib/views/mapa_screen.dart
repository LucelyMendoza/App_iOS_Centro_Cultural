import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_gallery_provider.dart';
import '../view_models/providers.dart';
import '../models/painting.dart';
import 'dart:math';

class MapaScreen extends ConsumerWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(paintingsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "¡Hola!",
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Utiliza nuestro plano interactivo",
                  style: TextStyle(
                    color: Color(0xFF84030C),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(Icons.location_on, color: Color(0xFF84030C)),
                    SizedBox(width: 4),
                    Text("San Agustin 106 - Arequipa"),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Stack(
                children: [
                  /// Mapa pintado
                  CustomPaint(
                    size: const Size(370, 443),
                    painter: MapaPainter(),
                  ),

                  /// Zona táctil para Galería I
                  Positioned(
                    left: 30,
                    top: 390,
                    width: 200,
                    height: 50,
                    child: GestureDetector(
                      onTap: () async {
                        final galleryId = 'galeria1'; // ID real en Firestore
                        final galleryTitle = 'Galería I';

                        final paintings = await ref
                            .read(paintingsViewModelProvider.notifier)
                            .fetchPaintingsFromFirestore(galleryId);

                        Navigator.pushNamed(
                          context,
                          '/paintings',
                          arguments: {
                            'galleryTitle': galleryTitle,
                            'paintings': paintings,
                          },
                        );
                      },

                      child: Container(
                        color: Colors.transparent,
                        height: 100,
                        width: 100,
                      ),
                    ),
                  ),

                  // Puedes repetir esto para otras galerías con su respectiva posición
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    textPainter(
      String text,
      Offset offset, {
      double fontSize = 12,
      Color color = Colors.black,
    }) {
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, offset);
    }

    // Función que dibuja texto girado 180
    void drawRotatedText(
      Canvas canvas,
      String text,
      Offset position,
      Color color,
    ) {
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 16),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();

      canvas.translate(position.dx, position.dy);

      canvas.rotate(pi);

      textPainter.paint(
        canvas,
        Offset(-textPainter.width, -textPainter.height),
      );

      canvas.restore();
    }

    // Dibujo de galerías
    canvas.drawRect(Rect.fromLTWH(30, 390, 200, 50), paint);
    textPainter('GALERÍA I', Offset(130, 410), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(30, 280, 60, 160), paint);
    textPainter('GALERÍA II', Offset(35, 320), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(90, 280, 140, 50), paint);
    textPainter('GALERÍA III', Offset(130, 300), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(290, 330, 50, 110), paint);
    textPainter('GALERÍA IV', Offset(290, 370), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(290, 280, 50, 50), paint);
    textPainter('GALERÍA V', Offset(290, 300), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(90, 110, 140, 50), paint);
    textPainter('LA SALA', Offset(140, 130), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(30, 110, 60, 130), paint);
    textPainter('GALERÍA VI', Offset(30, 170), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(290, 110, 50, 130), paint);

    canvas.drawCircle(Offset(315, 180), 10, Paint()..color = Colors.red);
    textPainter('X', Offset(311, 172), color: Colors.white);

    canvas.drawRect(Rect.fromLTWH(30, 13, 60, 95), paint);

    canvas.drawCircle(Offset(60, 65), 10, Paint()..color = Colors.red);
    textPainter('X', Offset(57, 57), color: Colors.white);

    canvas.drawRect(Rect.fromLTWH(90, 13, 250, 40), paint);

    canvas.drawCircle(Offset(220, 33), 10, Paint()..color = Colors.red);
    textPainter('X', Offset(217, 26), color: Colors.white);

    canvas.drawRect(Rect.fromLTWH(30, 13, 310, 430), paint);

    canvas.drawCircle(Offset(160, 80), 20, Paint()..color = Colors.grey);

    for (double i = 100; i <= 200; i += 45) {
      canvas.drawRect(
        Rect.fromLTWH(i, 230, 35, 10),
        Paint()..color = Colors.grey,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
