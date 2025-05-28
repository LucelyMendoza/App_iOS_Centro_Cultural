import 'package:flutter/material.dart';
import '../model/painting.dart';
import '../viewmodel/paintings_viewmodel.dart';
import 'painting_detail_screen.dart';



class PaintingsListScreen extends StatefulWidget {
  @override
  _PaintingsListScreenState createState() => _PaintingsListScreenState();
}

class _PaintingsListScreenState extends State<PaintingsListScreen> {
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
    // Aquí podrías abrir un modal para filtrar por autor, época, etc.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Filtrar'),
        content: Text('Aquí puedes agregar filtros personalizados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de obras', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Campo de búsqueda y botón de filtro
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: updateSearch,
                    decoration: InputDecoration(
                      labelText: 'Buscar obra',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  onPressed: filterDialog,
                  icon: Icon(Icons.filter_list),
                  tooltip: 'Filtrar',
                ),
              ],
            ),
            SizedBox(height: 12),
            // Lista de obras
            Expanded(
              child: ListView.builder(
                itemCount: filteredPaintings.length,
                itemBuilder: (context, index) {
                  final painting = filteredPaintings[index];
                  return Card(
                    color: Color(0xFFF7ECD8),
                    margin: EdgeInsets.symmetric(vertical: 6),
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
