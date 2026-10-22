import 'package:flutter/material.dart';

/// Bricolage Grotesque pour les titres et les prix, Figtree pour le texte.
/// Les tailles sont des estimations : la maquette n'en donne pas.
abstract final class Typographie {
  static const titre = 'BricolageGrotesque';
  static const texte = 'Figtree';

  static TextTheme construire(Color couleur) => TextTheme(
    headlineMedium: TextStyle(
      fontFamily: titre,
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.2,
      color: couleur,
    ),
    headlineSmall: TextStyle(
      fontFamily: titre,
      fontWeight: FontWeight.w700,
      fontSize: 24,
      height: 1.2,
      color: couleur,
    ),
    titleLarge: TextStyle(
      fontFamily: titre,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      height: 1.3,
      color: couleur,
    ),
    titleMedium: TextStyle(
      fontFamily: texte,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.4,
      color: couleur,
    ),
    titleSmall: TextStyle(
      fontFamily: texte,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.4,
      color: couleur,
    ),
    bodyLarge: TextStyle(
      fontFamily: texte,
      fontSize: 16,
      height: 1.5,
      color: couleur,
    ),
    bodyMedium: TextStyle(
      fontFamily: texte,
      fontSize: 14,
      height: 1.5,
      color: couleur,
    ),
    bodySmall: TextStyle(
      fontFamily: texte,
      fontSize: 12,
      height: 1.4,
      color: couleur,
    ),
    labelLarge: TextStyle(
      fontFamily: texte,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.2,
      color: couleur,
    ),
    labelMedium: TextStyle(
      fontFamily: texte,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 1.2,
      color: couleur,
    ),
    labelSmall: TextStyle(
      fontFamily: texte,
      fontWeight: FontWeight.w500,
      fontSize: 11,
      height: 1.2,
      color: couleur,
    ),
  );
}
