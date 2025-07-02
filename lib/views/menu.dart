import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'inicio.dart';
import 'mapa_screen.dart';
import 'paintings_list_screen.dart';
import 'ubicacion_page.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // Estilo iOS
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          activeColor: const Color(0xFF84030C),
          inactiveColor: const Color(0xFFE8D5A6),
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Búsqueda'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.location), label: 'Ubicación'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Mapa'),
          ],
        ),
        tabBuilder: (context, index) {
          final screens = [
            const Inicio(),
            const PaintingsListScreen(),
            UbicacionPage(),
            const MapaScreen(),
          ];
          return CupertinoPageScaffold(
            child: screens[index],
          );
        },
      );
    } else {
      // Estilo Android (Material)
      return const MenuMaterial();
    }
  }
}

class MenuMaterial extends StatefulWidget {
  const MenuMaterial({super.key});

  @override
  State<MenuMaterial> createState() => _MenuMaterialState();
}

class _MenuMaterialState extends State<MenuMaterial> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Inicio(),
    const PaintingsListScreen(),
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
        children: _screens,
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
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Búsqueda'),
                BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Ubicación'),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
