
import 'dart:convert';

import 'package:dropp/core/auth/session.dart';
import 'package:dropp/core/upload/service_upload.dart';
import 'package:dropp/features/vendeur/application/brouillon_kyc.dart';
import 'package:dropp/features/vendeur/data/modeles_kyc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

FichierLocal _photo(XFile file) =>
    FichierLocal(fichier: file, typeMime: 'image/jpeg', taille: 5*1024*1024);

ProviderContainer _conteneur() {
  final conteneur = ProviderContainer(
    overrides: [utilisateurConnecteProvider.overrideWithValue(null)],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

final fichiersTest = <XFile>[
  XFile.fromData(
    utf8.encode('Contenu du premier fichier de test'),
    name: 'document1.jpeg',
    mimeType: 'image/jpeg',
  ),
  XFile.fromData(
    utf8.encode('Contenu du deuxième fichier de test'),
    name: 'document2.jped',
    mimeType: 'image/jpeg',
  ),
  XFile.fromData(
    utf8.encode('Contenu du troisieme fichier de test'),
    name: 'document2.jpeg',
    mimeType: 'image/jpeg',
  ),
];

void main() {
  test('une photo choisie attend sa validation, puis est envoyée', () {
    final conteneur = _conteneur();
    final notifier = conteneur.read(brouillonKycProvider.notifier);

    notifier.choisir(TypeDocumentKyc.cniRecto, _photo(fichiersTest[1]));
    expect(
      conteneur.read(brouillonKycProvider).enAttenteDEnvoi(TypeDocumentKyc.cniRecto),
      isTrue,
    );

    notifier.marquerEnvoyee(TypeDocumentKyc.cniRecto);
    final etat = conteneur.read(brouillonKycProvider);
    expect(etat.enAttenteDEnvoi(TypeDocumentKyc.cniRecto), isFalse);
    expect(etat.photo(TypeDocumentKyc.cniRecto), isNotNull);
  });

  test('remplacer une photo envoyée la remet en attente', () {
    final conteneur = _conteneur();
    final notifier = conteneur.read(brouillonKycProvider.notifier)
      ..choisir(TypeDocumentKyc.cniRecto, _photo(fichiersTest[1]))
      ..marquerEnvoyee(TypeDocumentKyc.cniRecto)
      ..choisir(TypeDocumentKyc.cniRecto, _photo(fichiersTest[2]));

    final etat = conteneur.read(brouillonKycProvider);
    expect(etat.enAttenteDEnvoi(TypeDocumentKyc.cniRecto), isTrue);
    expect(etat.photo(TypeDocumentKyc.cniRecto)?.fichier, fichiersTest[2]);
    notifier.retirer(TypeDocumentKyc.cniRecto);
    expect(conteneur.read(brouillonKycProvider).photos, isEmpty);
  });

  test('vider efface tout', () {
    final conteneur = _conteneur();
    conteneur.read(brouillonKycProvider.notifier)
      ..choisir(TypeDocumentKyc.photoFaciale, _photo(fichiersTest[3]))
      ..vider();
    expect(conteneur.read(brouillonKycProvider).photos, isEmpty);
  });
}