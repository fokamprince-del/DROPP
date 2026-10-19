import 'package:flutter/material.dart';

/// Affichée le temps de lire la session au lancement.
class PageDemarrage extends StatelessWidget {
  const PageDemarrage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
