import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/icons.dart';
import '../../data/modeles_catalogue.dart';

/// Fourchettes de prix de la maquette (FCFA).
const fourchettesPrix = <(int?, int?)>[
  (null, 10000),
  (10000, 25000),
  (25000, 50000),
  (50000, null),
];

String libelleTri(AppLocalizations l10n, TriCatalogue tri) => switch (tri) {
  TriCatalogue.recents => l10n.triRecents,
  TriCatalogue.prixCroissant => l10n.triPrixCroissant,
  TriCatalogue.prixDecroissant => l10n.triPrixDecroissant,
  TriCatalogue.populaires => l10n.triPopulaires,
};

/// Ouvre les filtres ; renvoie les nouveaux filtres, ou `null` si fermé.
Future<FiltresCatalogue?> ouvrirFiltres(
  BuildContext context,
  FiltresCatalogue filtres,
) => showModalBottomSheet<FiltresCatalogue>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FeuilleFiltres(initiaux: filtres),
);

class _FeuilleFiltres extends StatefulWidget {
  const _FeuilleFiltres({required this.initiaux});

  final FiltresCatalogue initiaux;

  @override
  State<_FeuilleFiltres> createState() => _FeuilleFiltresState();
}

class _FeuilleFiltresState extends State<_FeuilleFiltres> {
  late FiltresCatalogue _filtres = widget.initiaux;
  late final _min = TextEditingController(text: _texte(_filtres.prixMin));
  late final _max = TextEditingController(text: _texte(_filtres.prixMax));

  static String _texte(int? valeur) => valeur?.toString() ?? '';

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _fourchette(int? min, int? max) {
    setState(() {
      _filtres = _filtres.avec(prixMin: min, prixMax: max);
      _min.text = _texte(min);
      _max.text = _texte(max);
    });
  }

  void _reinitialiser() {
    setState(() {
      _filtres = _filtres.sansFiltres();
      _min.clear();
      _max.clear();
    });
  }

  void _appliquer() {
    var min = int.tryParse(_min.text);
    var max = int.tryParse(_max.text);
    // Min et max inversés : on les remet dans l'ordre plutôt que de bloquer.
    if (min != null && max != null && min > max) (min, max) = (max, min);
    Navigator.pop(context, _filtres.avec(prixMin: min, prixMax: max));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final titre = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
    );

    Widget champPrix(TextEditingController controleur, String libelle) =>
        Expanded(
          child: TextField(
            controller: controleur,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: libelle, suffixText: 'FCFA'),
          ),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Espacements.l,
          0,
          Espacements.l,
          Espacements.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.filtresTitre,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Espacements.l),
            Text(l10n.filtresPrix, style: titre),
            const SizedBox(height: Espacements.s),
            Row(
              children: [
                champPrix(_min, l10n.filtresPrixMin),
                const SizedBox(width: Espacements.s),
                champPrix(_max, l10n.filtresPrixMax),
              ],
            ),
            const SizedBox(height: Espacements.s),
            Wrap(
              spacing: Espacements.s,
              runSpacing: Espacements.s,
              children: [
                for (final (min, max) in fourchettesPrix)
                  ChoiceChip(
                    label: Text(_libelleFourchette(l10n, min, max)),
                    selected:
                        _min.text == _texte(min) && _max.text == _texte(max),
                    onSelected: (_) => _fourchette(min, max),
                  ),
              ],
            ),
            const SizedBox(height: Espacements.xl),
            Text(l10n.filtresTri, style: titre),
            for (final tri in TriCatalogue.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(libelleTri(l10n, tri)),
                selected: _filtres.tri == tri,
                trailing: FaIcon(
                  _filtres.tri == tri
                      ? IconesDropp.circleDot
                      : IconesDropp.circle,
                  color: _filtres.tri == tri ? schema.primary : schema.outline,
                ),
                onTap: () => setState(() => _filtres = _filtres.avec(tri: tri)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.filtresEnStock),
              value: _filtres.enStock,
              onChanged: (v) =>
                  setState(() => _filtres = _filtres.avec(enStock: v)),
            ),
            const SizedBox(height: Espacements.l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reinitialiser,
                    child: Text(l10n.filtresReinitialiser),
                  ),
                ),
                const SizedBox(width: Espacements.s),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _appliquer,
                    child: Text(l10n.filtresAppliquer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _libelleFourchette(AppLocalizations l10n, int? min, int? max) {
    String f(int v) => formaterNombre(v);
    if (min == null) return l10n.prixMoinsDe(f(max!));
    if (max == null) return l10n.prixPlusDe(f(min));
    return '${f(min)} – ${f(max)}';
  }
}

/// `25 000` (séparateur des milliers français).
String formaterNombre(int valeur) {
  final chiffres = valeur.toString();
  final morceaux = <String>[];
  for (var fin = chiffres.length; fin > 0; fin -= 3) {
    morceaux.insert(0, chiffres.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return morceaux.join(' ');
}
