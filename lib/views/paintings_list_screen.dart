import 'package:flutter/material.dart';
import '../models/painting.dart';
import '../view_models/paintings_viewmodel.dart';
import 'painting_detail_screen.dart';

class PaintingsListScreen extends StatelessWidget {
  const PaintingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PaintingsListContent();
  }
}

class _PaintingsListContent extends StatefulWidget {
  @override
  __PaintingsListContentState createState() => __PaintingsListContentState();
}

class __PaintingsListContentState extends State<_PaintingsListContent> {
  final PaintingsViewModel viewModel = PaintingsViewModel();
  List<Painting> filteredPaintings = [];
  String searchQuery = '';
  bool isLoading = true;

  Widget buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
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
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    viewModel.loadPaintings().then((_) {
      setState(() {
        filteredPaintings = viewModel.allPaintings;
        isLoading = false;
      });
    });
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredPaintings = viewModel.filterPaintings(query);
    });
  }

  void filterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filtrar'),
        content: const Text('Aquí puedes agregar filtros personalizados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lista de obras'),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: filterDialog,
              tooltip: 'Filtrar',
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: updateSearch,
                      decoration: InputDecoration(
                        hintText: 'Buscar obra...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPaintings.length,
                itemBuilder: (context, index) {
                  final painting = filteredPaintings[index];
                  return Card(
                    color: const Color(0xFFF7ECD8),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: SizedBox(
                        width: 60,
                        height: 60,
                        child: buildImage(painting.imagePath),
                      ),
                      title: Text(painting.title),
                      subtitle: Text(painting.author),
                      onTap: () =>
                          viewModel.goToPaintingDetail(context, painting),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
