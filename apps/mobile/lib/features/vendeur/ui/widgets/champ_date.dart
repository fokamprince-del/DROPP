import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/forms/champ_dropp.dart';
import '../../../../shared/forms/erreur_champ.dart';
import '../../domain/formulaire_cni.dart';
import 'formateur_date.dart';

/// Date saisie au clavier (`JJ/MM/AAAA`), avec le calendrier en secours.
class ChampDate extends StatelessWidget {
  const ChampDate({
    super.key,
    required this.libelle,
    required this.controleur,
    required this.validateur,
    required this.premierJour,
    required this.dernierJour,
    this.surChangement,
    this.actif = true,
    this.aide,
    this.couleurAide,
    this.actionClavier = TextInputAction.next,
  });

  final String libelle;
  final TextEditingController controleur;
  final ErreurChamp? Function(String?) validateur;
  final DateTime premierJour;
  final DateTime dernierJour;
  final ValueChanged<String>? surChangement;
  final bool actif;
  final String? aide;
  final Color? couleurAide;
  final TextInputAction actionClavier;

  Future<void> _choisir(BuildContext context) async {
    final aide = context.l10n.kycChoisirDate;
    final actuel = analyserDateSaisie(controleur.text);
    var initial = actuel == null
        ? dernierJour
        : DateTime(actuel.year, actuel.month, actuel.day);
    if (initial.isBefore(premierJour)) initial = premierJour;
    if (initial.isAfter(dernierJour)) initial = dernierJour;

    final choisi = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: premierJour,
      lastDate: dernierJour,
      helpText: aide,
    );
    if (choisi == null) return;
    controleur.text = formaterJour(
      DateTime.utc(choisi.year, choisi.month, choisi.day),
    );
    surChangement?.call(controleur.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ChampDropp(
      libelle: libelle,
      controleur: controleur,
      validateur: validateur,
      typeClavier: TextInputType.number,
      actionClavier: actionClavier,
      formateurs: [FormateurDateJour()],
      surChangement: surChangement,
      actif: actif,
      aide: aide ?? l10n.kycFormatDate,
      couleurAide: couleurAide,
      suffixe: IconButton(
        tooltip: l10n.kycChoisirDate,
        icon: const Icon(Icons.calendar_today_outlined),
        onPressed: actif ? () => unawaited(_choisir(context)) : null,
      ),
    );
  }
}
