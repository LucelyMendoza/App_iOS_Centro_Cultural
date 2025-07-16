import 'package:flutter/material.dart';
import 'dart:math';

class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(title: Text(""), backgroundColor: Color(0xFFFFFFFF)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "¡Hola!",
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Utiliza nuestro plano interactivo",
                  style: TextStyle(
                    color: Color(0xFF84030C),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF84030C)),
                    SizedBox(width: 4),
                    Text("San Agustin 106 - Arequipa"),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF84030C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Ubicación no disponible por ahora"),
                      ),
                    );
                  },
                  child: Text(
                    "Determine su ubicación",
                    style: TextStyle(color: Color(0xFFD1AA65), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CustomPaint(painter: MapaPainter(), child: Container()),
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
    canvas.drawRect(Rect.fromLTWH(30, 370, 200, 70), paint);
    textPainter('GALERÍA I', Offset(130, 400), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(30, 280, 60, 160), paint);
    textPainter('GALERÍA II', Offset(35, 320), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(90, 280, 140, 40), paint);
    textPainter('GALERÍA III', Offset(125, 105), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(250, 30, 60, 60), paint);
    textPainter('GALERÍA IV', Offset(255, 50), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(250, 100, 60, 60), paint);
    textPainter('GALERÍA V', Offset(255, 120), color: Color(0xFFD1AA65));

    canvas.drawRect(Rect.fromLTWH(180, 200, 120, 60), paint);
    textPainter('LA SALA', Offset(200, 225), color: Color(0xFFD1AA65));

    canvas.drawCircle(Offset(250, 180), 10, Paint()..color = Colors.red);
    textPainter('X', Offset(245, 172), color: Colors.white);

    for (double i = 50; i <= 180; i += 60) {
      canvas.drawRect(
        Rect.fromLTWH(i, 250, 20, 10),
        Paint()..color = Colors.brown,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
