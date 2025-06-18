import 'package:flutter/material.dart';
import '../models/gallery.dart';
import '../models/painting.dart';
import '../view_models/paintings_viewmodel.dart';

class GalleryDetail extends StatelessWidget {
  final Gallery gallery;
  final PaintingsViewModel _paintingsVM = PaintingsViewModel();

  GalleryDetail({Key? key, required this.gallery}) : super(key: key);

  Widget buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else {
      return Image.asset(path, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Painting> paintings = _paintingsVM.allPaintings
        .where(
          (p) =>
              p.gallery.toLowerCase().trim() ==
              gallery.title.toLowerCase().trim(),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(gallery.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 100, width: double.infinity),
              const SizedBox(height: 16),
              Text(
                gallery.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gallery.location,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pinturas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: paintings.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final painting = paintings[index];
                    return GestureDetector(
                      onTap: () =>
                          _paintingsVM.goToPaintingDetail(context, painting),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: buildImage(painting.imagePath),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    painting.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    painting.author,
                                    style: const TextStyle(color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
