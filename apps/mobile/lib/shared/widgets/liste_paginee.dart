import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/pagination.dart';
import '../../core/l10n/contexte_l10n.dart';
import 'vue_erreur.dart';

/// Liste à défilement infini sur une route paginée de l'API, avec « tirer pour
/// rafraîchir », états chargement / vide / erreur et bouton Réessayer.
///
/// ```dart
/// ListePaginee<Produit>(
///   charger: (page) => api.page('/produits', Produit.fromJson, page: page),
///   elementBuilder: (context, produit, _) => CarteProduit(produit),
/// )
/// ```
///
/// Pour recharger ou modifier un élément (like optimiste…), passer une
/// `GlobalKey<ListePagineeState<T>>` et appeler `recharger()` ou
/// `mettreAJour()`.
class ListePaginee<T> extends StatefulWidget {
  const ListePaginee({
    super.key,
    required this.charger,
    required this.elementBuilder,
    this.separateur,
    this.enTete,
    this.vide,
    this.squelette,
    this.auRafraichir,
    this.padding,
  });

  final Future<PageResultats<T>> Function(int page) charger;
  final Widget Function(BuildContext context, T element, int index)
  elementBuilder;
  final Widget? separateur;

  /// Affiché au-dessus du premier élément (filtres, bannière…).
  final Widget? enTete;
  final Widget? vide;

  /// Affiché au premier chargement à la place du spinner.
  final Widget? squelette;

  /// Appelé avec « tirer pour rafraîchir », en même temps que le
  /// rechargement de la liste : pour ce qui vit dans l'en-tête.
  final Future<void> Function()? auRafraichir;
  final EdgeInsetsGeometry? padding;

  @override
  State<ListePaginee<T>> createState() => ListePagineeState<T>();
}

class ListePagineeState<T> extends State<ListePaginee<T>> {
  static const _seuilChargement = 600.0;

  final _defilement = ScrollController();
  final _elements = <T>[];
  int _page = 0;
  bool _aSuivante = true;
  bool _chargement = false;
  ApiException? _erreur;

  /// Incrémenté à chaque rechargement : une réponse d'avant est ignorée.
  int _generation = 0;

  List<T> get elements => List.unmodifiable(_elements);

  @override
  void initState() {
    super.initState();
    _defilement.addListener(_surDefilement);
    // setState est interdit pendant initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chargerSuivante();
    });
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  Future<void> recharger() async {
    _generation++;
    setState(() {
      _elements.clear();
      _page = 0;
      _aSuivante = true;
      _chargement = false;
      _erreur = null;
    });
    await _chargerSuivante();
  }

  /// Remplace les éléments qui vérifient [test] (mise à jour optimiste).
  void mettreAJour(bool Function(T) test, T Function(T) maj) {
    setState(() {
      for (var i = 0; i < _elements.length; i++) {
        if (test(_elements[i])) _elements[i] = maj(_elements[i]);
      }
    });
  }

  void retirer(bool Function(T) test) =>
      setState(() => _elements.removeWhere(test));

  void _surDefilement() {
    if (_defilement.position.extentAfter < _seuilChargement) _chargerSuivante();
  }

  Future<void> _chargerSuivante() async {
    if (_chargement || !_aSuivante) return;
    final generation = _generation;
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final page = await widget.charger(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _elements.addAll(page.donnees);
        _page = page.pagination.page;
        _aSuivante = page.pagination.aSuivante && page.donnees.isNotEmpty;
        _chargement = false;
      });
      // Première page trop courte pour défiler : charger la suivante.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _defilement.hasClients &&
            _defilement.position.maxScrollExtent <= 0) {
          _chargerSuivante();
        }
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _erreur = ApiException.depuis(e);
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final enTete = widget.enTete;
    final decalage = enTete == null ? 0 : 1;

    final Widget contenu;
    if (_elements.isEmpty) {
      final enAttente = _erreur == null && (_chargement || _aSuivante);
      contenu = ListView(
        controller: _defilement,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        children: [
          ?enTete,
          if (enAttente && widget.squelette != null)
            widget.squelette!
          else if (!enAttente && _erreur == null && widget.vide != null)
            widget.vide!
          else
            SizedBox(
              height: 320,
              child: Center(
                child: _erreur != null
                    ? VueErreur(erreur: _erreur!, reessayer: recharger)
                    : enAttente
                    ? const CircularProgressIndicator()
                    : Text(context.l10n.rienAAfficher),
              ),
            ),
        ],
      );
    } else {
      contenu = ListView.separated(
        controller: _defilement,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: decalage + _elements.length + 1,
        separatorBuilder: (context, index) => index < decalage
            ? const SizedBox.shrink()
            : widget.separateur ?? const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index < decalage) return enTete!;
          final i = index - decalage;
          if (i < _elements.length) {
            return widget.elementBuilder(context, _elements[i], i);
          }
          return _PiedDeListe(
            chargement: _chargement,
            erreur: _erreur,
            reessayer: _chargerSuivante,
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([recharger(), ?widget.auRafraichir?.call()]);
      },
      child: contenu,
    );
  }
}

class _PiedDeListe extends StatelessWidget {
  const _PiedDeListe({
    required this.chargement,
    required this.erreur,
    required this.reessayer,
  });

  final bool chargement;
  final ApiException? erreur;
  final VoidCallback reessayer;

  @override
  Widget build(BuildContext context) {
    if (erreur != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: VueErreur(erreur: erreur!, reessayer: reessayer),
      );
    }
    if (!chargement) return const SizedBox(height: 24);
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
