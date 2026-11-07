import 'package:flutter/services.dart';

/// Saisie d'une date : chiffres seulement, barres insérées après le jour et le
/// mois (`21051990` → `21/05/1990`). Le curseur reste à la fin.
class FormateurDateJour extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue ancien,
    TextEditingValue nouveau,
  ) {
    final chiffres = nouveau.text.replaceAll(RegExp(r'\D'), '');
    final gardes = chiffres.length > 8 ? chiffres.substring(0, 8) : chiffres;
    final tampon = StringBuffer();
    for (var i = 0; i < gardes.length; i++) {
      if (i == 2 || i == 4) tampon.write('/');
      tampon.write(gardes[i]);
    }
    final texte = tampon.toString();
    return TextEditingValue(
      text: texte,
      selection: TextSelection.collapsed(offset: texte.length),
    );
  }
}
