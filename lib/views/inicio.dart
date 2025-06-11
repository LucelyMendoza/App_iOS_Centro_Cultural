import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/home_view_model.dart';

class Inicio extends ConsumerWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Artista Destacado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  state.featuredArtist?.image ?? 'assets/prueba.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.featuredArtist?.name ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(state.featuredArtist?.username ?? ''),

              const Divider(height: 32),
              const Text(
                'Galerías',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ListView.builder(
                itemCount: state.galleries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final gallery = state.galleries[index];
                  return Card(
                    child: ListTile(
                      leading: Image.asset(gallery.image, width: 50, fit: BoxFit.cover),
                      title: Text(gallery.title),
                      subtitle: Text(gallery.location),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}