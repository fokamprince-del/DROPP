import 'package:flutter/painting.dart';

/// Palette « Ndop » (direction visuelle DROPP).
abstract final class Couleurs {
  // ── Valeurs de la maquette ──
  static const indigo = Color(0xFF23307A);
  static const hibiscus = Color(0xFFD6336C);
  static const coton = Color(0xFFF5F6FA);
  static const encre = Color(0xFF151936);
  static const plantain = Color(0xFF1F8A5B);
  static const kola = Color(0xFFC98A0B);
  static const piment = Color(0xFFD2402B);

  static const nuit = Color(0xFF0B1029);
  static const nuitCarte = Color(0xFF141A3D);
  static const indigoClair = Color(0xFF8C9BFF);
  static const hibiscusVif = Color(0xFFFF5C93);

  // Fonds secondaires (puces, squelettes) et texte secondaire.
  static const surface2 = Color(0xFFECEEF6);
  static const texte2 = Color(0xFF4A5078);
  static const surface2Sombre = Color(0xFF1C2350);
  static const texte2Sombre = Color(0xFFB3B8DA);

  /// Fond des vidéos et des stories.
  static const nuitTeinte = Color(0xFF0E1433);

  /// Prix posé sur un média (fond sombre).
  static const hibiscusDoux = Color(0xFFFF8AB0);

  // ── Ajouts : valeurs estimées, à valider visuellement ──
  static const blanc = Color(0xFFFFFFFF);
  static const bordure = Color(0xFF7F87B0);
  static const bordureSombre = Color(0xFF6B74B0);
  static const texteSombre = Color(0xFFF1F2FA);

  // Variantes pour le TEXTE (contraste ≥ 4,5 : 1, vérifié par un test).
  static const plantainTexte = Color(0xFF17714A);
  static const kolaTexte = Color(0xFF8A5A00);
  static const pimentTexte = Color(0xFFB8321F);

  // Fonds pastel des badges et bandeaux.
  static const plantainFond = Color(0xFFE1F3EA);
  static const kolaFond = Color(0xFFFBF0D9);
  static const pimentFond = Color(0xFFFBE4E0);

  // Thème sombre : textes clairs et fonds teintés.
  static const plantainTexteSombre = Color(0xFF4CC38A);
  static const kolaTexteSombre = Color(0xFFF0B84A);
  static const pimentTexteSombre = Color(0xFFFF8A75);
  static const plantainFondSombre = Color(0xFF12301F);
  static const kolaFondSombre = Color(0xFF33270E);
  static const pimentFondSombre = Color(0xFF3A1A14);

  // Filets décoratifs (séparateurs, barre d'onglets).
  static const separateur = Color(0xFFD9DCE8);
  static const separateurSombre = Color(0xFF2A3160);

  // Texte secondaire, sans transparence.
  static const texteSecondaire = Color(0xFF454B70); // 8,4 sur blanc
  static const texteSecondaireSombre = Color(0xFFB4BBE3); // 9,0 sur la carte
}
