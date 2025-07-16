import 'package:flutter/material.dart';
import '../models/painting.dart';

class PaintingDetailScreen extends StatelessWidget {
  final Painting painting;

  const PaintingDetailScreen({super.key, required this.painting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Detalles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  painting.imagePath,
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              painting.title,
              style: const TextStyle(
                color: Color(0xFF7E0303),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 6),

            // Galería con ícono
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 6),
                Text(
                  painting.gallery,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Autor y año en la misma línea
            Text(
              '${painting.author} · ${painting.year}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),

            const SizedBox(height: 12),

            // Descripción y botón de audio al costado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    painting.details,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {
                      // Aquí iría tu lógica de TextToSpeech
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
