import 'package:flutter/material.dart';

import '../l10n/contexte_l10n.dart';

/// Barre d'onglets de la maquette : 5 entrées, le panier (index 2) en bouton
/// plein au centre, pastilles de compteur sur le panier et les messages.
class BarreNavigation extends StatelessWidget {
  const BarreNavigation({
    super.key,
    required this.indexSelectionne,
    required this.surSelection,
    this.nombrePanier = 0,
    this.nombreMessages = 0,
  });

  static const indexPanier = 2;

  final int indexSelectionne;
  final ValueChanged<int> surSelection;
  final int nombrePanier;
  final int nombreMessages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schema = Theme.of(context).colorScheme;

    final entrees = <_Entree>[
      _Entree(
        Icons.home_outlined,
        Icons.home,
        l10n.navAccueil,
        l10n.navAccueil,
      ),
      _Entree(Icons.search, Icons.search, l10n.navDecouvrir, l10n.navDecouvrir),
      _Entree(
        Icons.shopping_bag_outlined,
        Icons.shopping_bag,
        l10n.navPanier,
        nombrePanier > 0
            ? l10n.navPanierArticles(nombrePanier)
            : l10n.navPanier,
        compteur: nombrePanier,
      ),
      _Entree(
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        l10n.navMessages,
        nombreMessages > 0
            ? l10n.navMessagesNonLus(nombreMessages)
            : l10n.navMessages,
        compteur: nombreMessages,
      ),
      _Entree(
        Icons.person_outline,
        Icons.person,
        l10n.navProfil,
        l10n.navProfil,
      ),
    ];

    return Material(
      color: schema.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: schema.outline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < entrees.length; i++)
                  Expanded(
                    child: _ItemBarre(
                      entree: entrees[i],
                      selectionne: i == indexSelectionne,
                      central: i == indexPanier,
                      surTouche: () => surSelection(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Entree {
  const _Entree(
    this.icone,
    this.iconeActive,
    this.libelle,
    this.libelleAccessible, {
    this.compteur = 0,
  });

  final IconData icone;
  final IconData iconeActive;
  final String libelle;
  final String libelleAccessible;
  final int compteur;
}

class _ItemBarre extends StatelessWidget {
  const _ItemBarre({
    required this.entree,
    required this.selectionne,
    required this.central,
    required this.surTouche,
  });

  final _Entree entree;
  final bool selectionne;
  final bool central;
  final VoidCallback surTouche;

  /// Ajoute la pastille de compteur autour de [enfant], s'il y a lieu.
  Widget _avecPastille(BuildContext context, Widget enfant) {
    if (entree.compteur <= 0) return enfant;
    final schema = Theme.of(context).colorScheme;
    return Badge(
      label: Text(entree.compteur > 99 ? '99+' : '${entree.compteur}'),
      backgroundColor: schema.secondary,
      textColor: schema.onSecondary,
      child: enfant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final couleurTexte = selectionne
        ? schema.onSurface
        : schema.onSurface.withValues(alpha: 0.65);

    final icone = Icon(
      selectionne ? entree.iconeActive : entree.icone,
      color: central ? schema.onPrimary : couleurTexte,
    );

    // Bouton central : la pastille entoure le bouton plein.
    // Autres onglets : elle entoure l'icône.
    final Widget contenu = central
        ? _avecPastille(
            context,
            Container(
              width: 52,
              height: 44,
              decoration: BoxDecoration(
                color: schema.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: icone),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avecPastille(context, icone),
              const SizedBox(height: 2),
              Text(
                entree.libelle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: couleurTexte,
                  fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      selected: selectionne,
      label: entree.libelleAccessible,
      excludeSemantics: true,
      child: InkWell(
        onTap: surTouche,
        child: Center(child: contenu),
      ),
    );
  }
}
