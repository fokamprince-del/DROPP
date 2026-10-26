import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/theme/rayons.dart';
import '../../domain/validateurs.dart';

/// Le contrôleur ne doit pas changer pendant la vie du widget.
class ChampCode extends StatefulWidget {
  const ChampCode({
    super.key,
    required this.controleur,
    this.surComplet,
    this.erreur,
    this.actif = true,
  });

  final TextEditingController controleur;

  /// Appelé une fois quand les 6 chiffres sont saisis.
  final ValueChanged<String>? surComplet;
  final String? erreur;
  final bool actif;

  @override
  State<ChampCode> createState() => _ChampCodeState();
}

class _ChampCodeState extends State<ChampCode> {
  final _focus = FocusNode();
  String? _dernierComplet;

  @override
  void initState() {
    super.initState();
    widget.controleur.addListener(_changement);
    _focus.addListener(_rafraichir);
  }

  @override
  void dispose() {
    widget.controleur.removeListener(_changement);
    _focus
      ..removeListener(_rafraichir)
      ..dispose();
    super.dispose();
  }

  void _rafraichir() => setState(() {});

  void _changement() {
    final texte = widget.controleur.text;
    if (texte.length == longueurCode) {
      if (texte != _dernierComplet) {
        _dernierComplet = texte;
        widget.surComplet?.call(texte);
      }
    } else {
      _dernierComplet = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final texte = widget.controleur.text;
    final caseActive = _focus.hasFocus
        ? texte.length.clamp(0, longueurCode - 1)
        : -1;
    final invisible = Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < longueurCode; i++)
                      Container(
                        width: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: schema.surface,
                          borderRadius: Rayons.borduresChamp,
                          border: Border.all(
                            color: widget.erreur != null
                                ? schema.error
                                : i == caseActive
                                ? schema.primary
                                : schema.outline,
                            width: i == caseActive ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          i < texte.length ? texte[i] : '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: TextField(
                  controller: widget.controleur,
                  focusNode: _focus,
                  enabled: widget.actif,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(longueurCode),
                  ],
                  style: TextStyle(color: invisible),
                  cursorColor: invisible,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                    hintText: context.l10n.champCode,
                    hintStyle: TextStyle(color: invisible),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.erreur != null)
          Padding(
            padding: const EdgeInsets.only(top: Espacements.s),
            child: Text(
              widget.erreur!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: schema.error),
            ),
          ),
      ],
    );
  }
}
