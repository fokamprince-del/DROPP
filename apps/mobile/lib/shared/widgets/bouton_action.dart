import 'package:flutter/material.dart';

class BoutonAction extends StatelessWidget {
  const BoutonAction({
    super.key,
    required this.libelle,
    required this.enCours,
    required this.surAppui,
  });

  final String libelle;
  final bool enCours;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enCours ? null : surAppui,
        child: enCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(libelle),
      ),
    );
  }
}
