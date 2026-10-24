import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/widgets/champ_dropp.dart';
import '../../domain/validateurs.dart';

/// Le contrôleur est créé par l'écran avec `TextEditingController(text:
/// indicatifParDefaut)`. La valeur à envoyer est `normaliserTelephone(texte)`.
class ChampTelephone extends StatelessWidget {
  const ChampTelephone({
    super.key,
    required this.controleur,
    this.actionClavier = TextInputAction.next,
    this.surSoumission,
    this.actif = true,
    this.erreurServeur,
  });

  final TextEditingController controleur;
  final TextInputAction actionClavier;
  final ValueChanged<String>? surSoumission;
  final bool actif;
  final String? erreurServeur;

  @override
  Widget build(BuildContext context) {
    return ChampDropp(
      libelle: context.l10n.champTelephone,
      controleur: controleur,
      validateur: validerTelephone,
      typeClavier: TextInputType.phone,
      actionClavier: actionClavier,
      indicesAutoRemplissage: const [AutofillHints.telephoneNumber],
      formateurs: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]'))],
      surSoumission: surSoumission,
      actif: actif,
      erreurServeur: erreurServeur,
    );
  }
}
