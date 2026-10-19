import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Barre d'onglets du bas. Chaque onglet garde sa propre pile de navigation.
class NavigationPrincipale extends StatelessWidget {
  const NavigationPrincipale({super.key, required this.coquille});

  final StatefulNavigationShell coquille;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: coquille,
      bottomNavigationBar: NavigationBar(
        selectedIndex: coquille.currentIndex,
        // Toucher l'onglet actif revient à sa racine.
        onDestinationSelected: (index) => coquille.goBranch(
          index,
          initialLocation: index == coquille.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Rechercher',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Panier',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
