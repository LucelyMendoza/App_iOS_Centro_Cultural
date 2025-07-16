import 'package:flutter/material.dart';
import '../view_models/paintings_viewmodel.dart';
import 'painting_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(paintingsViewModelAsyncProvider);

    return viewModel.when(
      data: (vm) {
        return Scaffold(
          appBar: AppBar(title: const Text('Galería de Pinturas')),
          body: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columnas
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: vm.paintings.length,
            itemBuilder: (context, index) {
              final painting = vm.paintings[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaintingDetailScreen(painting: painting),
                    ),
                  );
                },
                child: GridTile(
                  footer: GridTileBar(
                    backgroundColor: Colors.black54,
                    title: Text(painting.title),
                    subtitle: Text(painting.author),
                  ),
                  child: Image.asset(painting.imagePath, fit: BoxFit.cover),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
