import 'package:dropp/shared/theme/couleurs.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final haut = la > lb ? la : lb;
  final bas = la > lb ? lb : la;
  return (haut + 0.05) / (bas + 0.05);
}

void main() {
  const seuil = 4.5;

  // (texte, fond). Si une paire échoue, on corrige la couleur, pas le seuil.
  final paires = <String, (Color, Color)>{
    'encre / coton': (Couleurs.encre, Couleurs.coton),
    'encre / blanc': (Couleurs.encre, Couleurs.blanc),
    'blanc / indigo (bouton)': (Couleurs.blanc, Couleurs.indigo),
    'blanc / hibiscus (badge)': (Couleurs.blanc, Couleurs.hibiscus),
    'blanc / piment (bouton)': (Couleurs.blanc, Couleurs.piment),
    'kolaTexte / blanc': (Couleurs.kolaTexte, Couleurs.blanc),
    'kolaTexte / coton': (Couleurs.kolaTexte, Couleurs.coton),
    'kolaTexte / kolaFond': (Couleurs.kolaTexte, Couleurs.kolaFond),
    'plantainTexte / blanc': (Couleurs.plantainTexte, Couleurs.blanc),
    'plantainTexte / coton': (Couleurs.plantainTexte, Couleurs.coton),
    'plantainTexte / plantainFond': (
      Couleurs.plantainTexte,
      Couleurs.plantainFond,
    ),
    'pimentTexte / coton': (Couleurs.pimentTexte, Couleurs.coton),
    'pimentTexte / pimentFond': (Couleurs.pimentTexte, Couleurs.pimentFond),
    'texteSombre / nuit': (Couleurs.texteSombre, Couleurs.nuit),
    'texteSombre / nuitCarte': (Couleurs.texteSombre, Couleurs.nuitCarte),
    'nuit / indigoClair (bouton)': (Couleurs.nuit, Couleurs.indigoClair),
    'nuit / hibiscusVif': (Couleurs.nuit, Couleurs.hibiscusVif),
    'kolaTexteSombre / nuitCarte': (
      Couleurs.kolaTexteSombre,
      Couleurs.nuitCarte,
    ),
    'kolaTexteSombre / kolaFondSombre': (
      Couleurs.kolaTexteSombre,
      Couleurs.kolaFondSombre,
    ),
    'plantainTexteSombre / nuitCarte': (
      Couleurs.plantainTexteSombre,
      Couleurs.nuitCarte,
    ),
    'plantainTexteSombre / plantainFondSombre': (
      Couleurs.plantainTexteSombre,
      Couleurs.plantainFondSombre,
    ),
    'pimentTexteSombre / nuitCarte': (
      Couleurs.pimentTexteSombre,
      Couleurs.nuitCarte,
    ),
    'pimentTexteSombre / pimentFondSombre': (
      Couleurs.pimentTexteSombre,
      Couleurs.pimentFondSombre,
    ),
  };

  for (final entree in paires.entries) {
    test('contraste ≥ 4,5 : ${entree.key}', () {
      final (texte, fond) = entree.value;
      expect(contraste(texte, fond), greaterThanOrEqualTo(seuil));
    });
  }
}
