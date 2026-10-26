import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Pays supposé quand le numéro est saisi sans indicatif.
const paysParDefaut = IsoCode.CM;
const indicatifParDefaut = '+237 ';

/// Renvoie le numéro au format international (`+237670000001`), ou `null`
/// s'il est vide ou invalide. C'est ce format qui est envoyé à l'API, à
/// l'inscription comme à la connexion.
String? normaliserTelephone(String saisie, {IsoCode pays = paysParDefaut}) {
  var brut = saisie.replaceAll(RegExp(r'[\s().-]'), '');
  if (brut.isEmpty) return null;
  if (brut.startsWith('00')) brut = '+${brut.substring(2)}';

  try {
    final numero = brut.startsWith('+')
        ? PhoneNumber.parse(brut)
        : PhoneNumber.parse(brut, destinationCountry: pays);
    return numero.isValid() ? numero.international : null;
  } on Exception {
    return null;
  }
}

/// Masque le milieu d'un numéro pour l'afficher : `+237670 •• •• 01`.
/// Un texte trop court pour être un numéro est rendu tel quel.
String masquerTelephone(String numero) {
  if (numero.length < 8) return numero;
  final debut = numero.substring(0, numero.length - 6);
  final fin = numero.substring(numero.length - 2);
  return '$debut •• •• $fin';
}
