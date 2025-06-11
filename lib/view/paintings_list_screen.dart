import 'package:flutter/material.dart';
import '../model/painting.dart';
import '../viewmodel/paintings_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    filteredPaintings = viewModel.allPaintings;
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de obras', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: updateSearch,
                    decoration: const InputDecoration(
                      labelText: 'Buscar obra',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: filterDialog,
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filtrar',
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
                      leading: Image.asset(
                        painting.imagePath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(painting.title),
                      subtitle: Text(' ${painting.author}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaintingDetailScreen(painting: painting),
                          ),
                        );
                      },
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