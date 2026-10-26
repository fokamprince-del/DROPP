import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Prix toujours au format de la maquette : `25 000 FCFA`, quelle que soit
/// la langue.
String formaterPrix(num prix) =>
    '${NumberFormat.decimalPattern('fr').format(prix.round())} FCFA';

/// Durée d'une vidéo : `0:42`, `12:05`.
String formaterDuree(Duration duree) {
  final minutes = duree.inMinutes;
  final secondes = (duree.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secondes';
}

/// Compteur court : `950`, `1,2 k`, `3,4 M`.
String formaterCompteur(int valeur, String langue) =>
    NumberFormat.compact(locale: langue).format(valeur);

/// « il y a 5 min », « il y a 3 h »… puis la date au-delà d'une semaine.
String tempsRelatif(
  AppLocalizations l10n,
  DateTime date, {
  DateTime? maintenant,
}) {
  final ecart = (maintenant ?? DateTime.now()).difference(date);
  if (ecart.inMinutes < 1) return l10n.tempsInstant;
  if (ecart.inHours < 1) return l10n.tempsMinutes(ecart.inMinutes);
  if (ecart.inDays < 1) return l10n.tempsHeures(ecart.inHours);
  if (ecart.inDays < 7) return l10n.tempsJours(ecart.inDays);
  return DateFormat.MMMd(l10n.localeName).format(date);
}
