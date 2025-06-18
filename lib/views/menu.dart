import 'package:flutter/material.dart';
import 'inicio.dart';
import 'mapa_screen.dart';
import 'paintings_list_screen.dart';
import 'ubicacion_page.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Inicio(),
    const PaintingsListScreen(), // Cambiado directamente a tu widget
    UbicacionPage(),
    const MapaScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // Usamos IndexedStack para mantener el estado
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: const Color(0xFFFFFFFF),
              selectedItemColor: const Color(0xFF84030C),
              unselectedItemColor: const Color(0xFFE8D5A6),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              type: BottomNavigationBarType.fixed,
              onTap: _onTap,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Búsqueda',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
