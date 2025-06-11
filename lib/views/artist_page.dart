import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../view_models/artist_view_model.dart';

class ArtistPage extends ConsumerWidget {
  const ArtistPage({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar Artista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Usuario')),
            TextField(controller: imageController, decoration: const InputDecoration(labelText: 'URL de Imagen')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newArtist = Artist(
                id: 0, // el ID se autogenera en la base de datos
                name: nameController.text,
                username: usernameController.text,
                image: imageController.text,
              );
              ref.read(artistProvider.notifier).addArtist(newArtist);
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Artist artist, WidgetRef ref) {
    final nameController = TextEditingController(text: artist.name);
    final usernameController = TextEditingController(text: artist.username);
    final imageController = TextEditingController(text: artist.image);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Artista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Usuario')),
            TextField(controller: imageController, decoration: const InputDecoration(labelText: 'URL de Imagen')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final updatedArtist = Artist(
                id: artist.id, // mantenemos el mismo ID
                name: nameController.text,
                username: usernameController.text,
                image: imageController.text,
              );
              ref.read(artistProvider.notifier).updateArtist(updatedArtist);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artistas'),
        backgroundColor: const Color(0xFF84030C),
      ),
      body: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(artist.image)),
            title: Text(artist.name),
            subtitle: Text('@${artist.username}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(context, artist, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(artistProvider.notifier).deleteArtist(artist.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF84030C),
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
