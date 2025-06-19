import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/painting.dart';

class PaintingDetailScreen extends StatefulWidget {
  final Painting painting;

  const PaintingDetailScreen({super.key, required this.painting});

  @override
  _PaintingDetailScreenState createState() => _PaintingDetailScreenState();
}

class _PaintingDetailScreenState extends State<PaintingDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
  }

  void _speakDescription() async {
    await flutterTts.speak(widget.painting.details);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Widget buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 280,
        height: 280,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else {
      return Image.asset(
        path,
        width: 280,
        height: 280,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final painting = widget.painting;

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
                child: buildImage(painting.imagePath),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              painting.title,
              style: const TextStyle(
                color: Color(0xFF7E0303),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
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
            Text(
              '${painting.author} · ${painting.year}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 12),
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
                    onPressed: _speakDescription,
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
