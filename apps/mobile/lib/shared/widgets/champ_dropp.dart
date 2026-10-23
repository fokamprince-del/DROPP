import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../features/auth/domain/validateurs.dart';
import 'libelles_erreurs.dart';

class ChampDropp extends StatelessWidget {
  const ChampDropp({
    super.key,
    required this.libelle,
    required this.controleur,
    this.validateur,
    this.typeClavier,
    this.actionClavier = TextInputAction.next,
    this.indicesAutoRemplissage,
    this.masque = false,
    this.suffixe,
    this.formateurs,
    this.surChangement,
    this.surSoumission,
    this.longueurMax,
    this.actif = true,
    this.erreurServeur,
  });

  final String libelle;
  final TextEditingController controleur;
  final ErreurChamp? Function(String?)? validateur;
  final TextInputType? typeClavier;
  final TextInputAction actionClavier;
  final Iterable<String>? indicesAutoRemplissage;
  final bool masque;
  final Widget? suffixe;
  final List<TextInputFormatter>? formateurs;
  final ValueChanged<String>? surChangement;
  final ValueChanged<String>? surSoumission;
  final int? longueurMax;
  final bool actif;

  /// Erreur renvoyée par le serveur (déjà traduite) : prioritaire.
  final String? erreurServeur;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(libelle, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: Espacements.xs),
        TextFormField(
          controller: controleur,
          enabled: actif,
          obscureText: masque,
          keyboardType: typeClavier,
          textInputAction: actionClavier,
          autofillHints: indicesAutoRemplissage,
          inputFormatters: formateurs,
          maxLength: longueurMax,
          onChanged: surChangement,
          onFieldSubmitted: surSoumission,
          autovalidateMode: AutovalidateMode.onUnfocus,
          validator: validateur == null
              ? null
              : (valeur) => validateur!(valeur)?.libelle(l10n),
          decoration: InputDecoration(
            suffixIcon: suffixe,
            counterText: '',
            errorText: erreurServeur,
          ),
        ),
      ],
    );
  }
}
