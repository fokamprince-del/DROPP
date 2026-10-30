import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/couleurs_metier.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../../../shared/widgets/champ_dropp.dart';
import '../../domain/validateurs.dart';

class ChampMotDePasse extends StatefulWidget {
  const ChampMotDePasse({
    super.key,
    required this.controleur,
    this.libelle,
    this.nouveau = false,
    this.actionClavier = TextInputAction.done,
    this.surSoumission,
    this.actif = true,
    this.erreurServeur,
  });

  final TextEditingController controleur;
  final String? libelle;

  /// `true` : création ou changement (8 caractères minimum, indicateur de
  /// force). `false` : saisie d'un mot de passe existant (connexion).
  final bool nouveau;
  final TextInputAction actionClavier;
  final ValueChanged<String>? surSoumission;
  final bool actif;
  final String? erreurServeur;

  @override
  State<ChampMotDePasse> createState() => _ChampMotDePasseState();
}

class _ChampMotDePasseState extends State<ChampMotDePasse> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChampDropp(
          libelle: widget.libelle ?? l10n.champMotDePasse,
          controleur: widget.controleur,
          masque: !_visible,
          validateur: widget.nouveau ? validerNouveauMotDePasse : validerRequis,
          typeClavier: TextInputType.visiblePassword,
          actionClavier: widget.actionClavier,
          indicesAutoRemplissage: [
            if (widget.nouveau)
              AutofillHints.newPassword
            else
              AutofillHints.password,
          ],
          longueurMax: 128,
          surSoumission: widget.surSoumission,
          actif: widget.actif,
          erreurServeur: widget.erreurServeur,
          suffixe: IconButton(
            tooltip: _visible
                ? l10n.motDePasseMasquer
                : l10n.motDePasseAfficher,
            icon: FaIcon(
              _visible
                  ? IconesDropp.masquerMotDePasse
                  : IconesDropp.voirMotDePasse,
            ),
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
        if (widget.nouveau) _IndicateurForce(controleur: widget.controleur),
      ],
    );
  }
}

class _IndicateurForce extends StatelessWidget {
  const _IndicateurForce({required this.controleur});

  final TextEditingController controleur;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controleur,
      builder: (context, valeur, _) {
        final niveau = forceMotDePasse(valeur.text);
        if (valeur.text.isEmpty) return const SizedBox.shrink();

        final metier = context.couleursMetier;
        final schema = Theme.of(context).colorScheme;
        final couleur = switch (niveau) {
          <= 1 => metier.erreur,
          2 => metier.attente,
          _ => metier.succes,
        };
        final l10n = context.l10n;
        final texte = switch (niveau) {
          <= 1 => l10n.forceMotDePasse1,
          2 => l10n.forceMotDePasse2,
          3 => l10n.forceMotDePasse3,
          _ => l10n.forceMotDePasse4,
        };

        return Padding(
          padding: const EdgeInsets.only(top: Espacements.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 1; i <= 4; i++) ...[
                      if (i > 1) const SizedBox(width: Espacements.xs),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= niveau ? couleur : schema.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Espacements.xs),
              Text(
                texte,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: couleur),
              ),
            ],
          ),
        );
      },
    );
  }
}
