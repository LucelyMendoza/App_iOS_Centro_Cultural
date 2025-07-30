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

  // Filtros seleccionados
  String? selectedAuthor;
  String? selectedGallery;
  String? selectedYear;

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

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredPaintings = viewModel.filterPaintings(query);
    });
  }

  List<String> getUniqueAuthors() => viewModel.allPaintings.map((p) => p.author).toSet().toList();
  List<String> getUniqueGalleries() => viewModel.allPaintings.map((p) => p.gallery).toSet().toList();
  List<String> getUniqueYears() => viewModel.allPaintings.map((p) => p.year).toSet().toList();

  void filterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filtrar obras'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedAuthor,
                decoration: const InputDecoration(labelText: 'Autor'),
                items: getUniqueAuthors()
                    .map((author) => DropdownMenuItem(
                          value: author,
                          child: Text(author),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedAuthor = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGallery,
                decoration: const InputDecoration(labelText: 'Galería'),
                items: getUniqueGalleries()
                    .map((gallery) => DropdownMenuItem(
                          value: gallery,
                          child: Text(gallery),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedGallery = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: 'Año'),
                items: getUniqueYears()
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedYear = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedAuthor = null;
                selectedGallery = null;
                selectedYear = null;
                filteredPaintings = viewModel.allPaintings;
              });
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                filteredPaintings = viewModel.allPaintings.where((painting) {
                  final matchAuthor = selectedAuthor == null || painting.author == selectedAuthor;
                  final matchGallery = selectedGallery == null || painting.gallery == selectedGallery;
                  final matchYear = selectedYear == null || painting.year == selectedYear;
                  return matchAuthor && matchGallery && matchYear;
                }).toList();
              });
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
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
