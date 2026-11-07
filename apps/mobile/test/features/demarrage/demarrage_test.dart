import 'package:dropp/features/demarrage/demarrage.dart';
import 'package:dropp/features/demarrage/stockage_bienvenue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FauxStockage implements StockageBienvenue {
  _FauxStockage({this.echecLecture = false}) : vue = false;

  bool vue;
  final bool echecLecture;

  @override
  Future<bool> lireVue() async {
    if (echecLecture) throw Exception('lecture impossible');
    return vue;
  }

  @override
  Future<void> marquerVue() async => vue = true;
}

ProviderContainer _conteneur(_FauxStockage stockage) {
  final conteneur = ProviderContainer(
    overrides: [
      stockageBienvenueProvider.overrideWithValue(stockage),
      dureeMinimaleDemarrageProvider.overrideWithValue(Duration.zero),
    ],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

Future<void> _attendre() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('commence « en cours », sans décision sur la bienvenue', () {
    final etat = _conteneur(_FauxStockage()).read(demarrageProvider);
    expect(etat.termine, isFalse);
    expect(etat.bienvenueVue, isTrue);
  });

  test('première ouverture : termine avec la bienvenue non vue', () async {
    final conteneur = _conteneur(_FauxStockage());
    conteneur.read(demarrageProvider);
    await _attendre();
    final etat = conteneur.read(demarrageProvider);
    expect(etat.termine, isTrue);
    expect(etat.bienvenueVue, isFalse);
  });

  test('lecture impossible : on saute la bienvenue', () async {
    final conteneur = _conteneur(_FauxStockage(echecLecture: true));
    conteneur.read(demarrageProvider);
    await _attendre();
    final etat = conteneur.read(demarrageProvider);
    expect(etat.termine, isTrue);
    expect(etat.bienvenueVue, isTrue);
  });

  test('marquer la bienvenue la mémorise', () async {
    final stockage = _FauxStockage();
    final conteneur = _conteneur(stockage);
    conteneur.read(demarrageProvider);
    await _attendre();
    await conteneur.read(demarrageProvider.notifier).marquerBienvenueVue();
    expect(conteneur.read(demarrageProvider).bienvenueVue, isTrue);
    expect(stockage.vue, isTrue);
  });
}
