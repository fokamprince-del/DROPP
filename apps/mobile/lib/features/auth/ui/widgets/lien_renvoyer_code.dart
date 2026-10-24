import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/contexte_l10n.dart';

/// « Renvoyer le code » avec minuteur. [surRenvoyer] renvoie `true` si le
/// code a bien été renvoyé : le minuteur repart alors de zéro.
class LienRenvoyerCode extends StatefulWidget {
  const LienRenvoyerCode({
    super.key,
    required this.surRenvoyer,
    this.dureeAttente = 60,
  });

  final Future<bool> Function() surRenvoyer;
  final int dureeAttente;

  @override
  State<LienRenvoyerCode> createState() => _LienRenvoyerCodeState();
}

class _LienRenvoyerCodeState extends State<LienRenvoyerCode> {
  Timer? _minuteur;
  int _restant = 0;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _lancerMinuteur();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  void _lancerMinuteur() {
    _minuteur?.cancel();
    _restant = widget.dureeAttente;
    _minuteur = Timer.periodic(const Duration(seconds: 1), (minuteur) {
      if (!mounted) return;
      setState(() => _restant--);
      if (_restant <= 0) minuteur.cancel();
    });
  }

  Future<void> _renvoyer() async {
    setState(() => _envoi = true);
    final ok = await widget.surRenvoyer();
    if (!mounted) return;
    setState(() {
      _envoi = false;
      if (ok) _lancerMinuteur();
    });
  }

  String _formater(int secondes) =>
      '${secondes ~/ 60}:${(secondes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_restant > 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            l10n.renvoyerCodeDans(_formater(_restant)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: _envoi ? null : _renvoyer,
        child: Text(l10n.renvoyerCode),
      ),
    );
  }
}
