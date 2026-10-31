import 'package:flutter/material.dart';

import 'couleurs.dart';
import 'couleurs_metier.dart';
import 'rayons.dart';
import 'typographie.dart';

abstract final class ThemeDropp {
  static final ThemeData clair = _construire(
    schema: const ColorScheme(
      brightness: Brightness.light,
      primary: Couleurs.indigo,
      onPrimary: Couleurs.blanc,
      secondary: Couleurs.hibiscus,
      onSecondary: Couleurs.blanc,
      error: Couleurs.piment,
      onError: Couleurs.blanc,
      surface: Couleurs.blanc,
      onSurface: Couleurs.encre,
      surfaceContainerHighest: Couleurs.surface2,
      onSurfaceVariant: Couleurs.texte2,
      outline: Couleurs.bordure,
      outlineVariant: Couleurs.separateur,
    ),
    fond: Couleurs.coton,
    metier: CouleursMetier.clair,
  );

  static final ThemeData sombre = _construire(
    schema: const ColorScheme(
      brightness: Brightness.dark,
      primary: Couleurs.indigoClair,
      onPrimary: Couleurs.nuit,
      secondary: Couleurs.hibiscusVif,
      onSecondary: Couleurs.nuit,
      error: Couleurs.pimentTexteSombre,
      onError: Couleurs.nuit,
      surface: Couleurs.nuitCarte,
      onSurface: Couleurs.texteSombre,
      surfaceContainerHighest: Couleurs.surface2Sombre,
      onSurfaceVariant: Couleurs.texteSecondaireSombre,
      outline: Couleurs.bordureSombre,
      outlineVariant: Couleurs.separateurSombre,
    ),
    fond: Couleurs.nuit,
    metier: CouleursMetier.sombre,
  );

  static ThemeData _construire({
    required ColorScheme schema,
    required Color fond,
    required CouleursMetier metier,
  }) {
    final texte = Typographie.construire(schema.onSurface);
    final boutonForme = RoundedRectangleBorder(
      borderRadius: Rayons.borduresBouton,
    );
    OutlineInputBorder bordure(Color couleur, [double largeur = 1]) =>
        OutlineInputBorder(
          borderRadius: Rayons.borduresChamp,
          borderSide: BorderSide(color: couleur, width: largeur),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: schema,
      scaffoldBackgroundColor: fond,
      fontFamily: Typographie.texte,
      textTheme: texte,
      extensions: [metier],
      appBarTheme: AppBarTheme(
        backgroundColor: fond,
        foregroundColor: schema.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: texte.titleLarge,
      ),
      // Zones tactiles d'au moins 48 dp (contrainte de la maquette).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: boutonForme,
          textStyle: texte.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: boutonForme,
          side: BorderSide(color: schema.outline),
          textStyle: texte.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: texte.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: schema.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: bordure(schema.outline),
        enabledBorder: bordure(schema.outline),
        focusedBorder: bordure(schema.primary, 2),
        errorBorder: bordure(schema.error),
        focusedErrorBorder: bordure(schema.error, 2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: schema.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: Rayons.borduresFeuille,
        ),
      ),
    );
  }
}
