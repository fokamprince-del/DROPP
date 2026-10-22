import 'package:flutter/painting.dart';

/// Rayons de la maquette : 8 champs, 12 boutons, 16 cartes, 22 feuilles.
abstract final class Rayons {
  static const double champ = 8;
  static const double bouton = 12;
  static const double carte = 16;
  static const double feuille = 22;

  static final borduresChamp = BorderRadius.circular(champ);
  static final borduresBouton = BorderRadius.circular(bouton);
  static final borduresCarte = BorderRadius.circular(carte);
  static const borduresFeuille = BorderRadius.vertical(
    top: Radius.circular(feuille),
  );
}