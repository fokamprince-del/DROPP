import 'package:flutter/material.dart';

/// Écran vide en attendant le vrai : permet de brancher la navigation tout de
/// suite. À remplacer, puis supprimer quand plus aucune route ne l'utilise.
class PageProvisoire extends StatelessWidget {
  const PageProvisoire(this.titre, {super.key, this.actions = const []});

  final String titre;

  /// Boutons de test (aller à une page, se déconnecter…).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text('$titre — à venir', style: Theme.of(context).textTheme.titleMedium),
            ...actions,
          ],
        ),
      ),
    );
  }
}
