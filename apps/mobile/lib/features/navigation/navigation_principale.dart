import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'badges_navigation.dart';
import 'barre_navigation.dart';

/// Barre d'onglets du bas. Chaque onglet garde sa propre pile de navigation.
class NavigationPrincipale extends ConsumerWidget {
  const NavigationPrincipale({super.key, required this.coquille});

  final StatefulNavigationShell coquille;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: coquille,
      bottomNavigationBar: BarreNavigation(
        indexSelectionne: coquille.currentIndex,
        // Toucher l'onglet actif revient à sa racine.
        surSelection: (index) => coquille.goBranch(
          index,
          initialLocation: index == coquille.currentIndex,
        ),
        nombrePanier: ref.watch(nombreArticlesPanierProvider),
        nombreMessages: ref.watch(nombreMessagesNonLusProvider),
      ),
    );
  }
}
