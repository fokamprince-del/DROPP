import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stockage_bienvenue.dart';

/// Durée minimale de l'écran de démarrage (laisse finir l'animation du logo).
/// Surchargée à zéro dans les tests.
final dureeMinimaleDemarrageProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1200),
);

@immutable
class EtatDemarrage {
  const EtatDemarrage({required this.termine, required this.bienvenueVue});

  /// Au lancement : on n'a encore rien lu. `bienvenueVue` est à `true` pour
  /// qu'aucune décision ne soit prise avant la fin de la lecture.
  const EtatDemarrage.enCours() : termine = false, bienvenueVue = true;

  final bool termine;
  final bool bienvenueVue;
}

final demarrageProvider = NotifierProvider<DemarrageNotifier, EtatDemarrage>(
  DemarrageNotifier.new,
);

class DemarrageNotifier extends Notifier<EtatDemarrage> {
  @override
  EtatDemarrage build() {
    _charger();
    return const EtatDemarrage.enCours();
  }

  Future<void> _charger() async {
    final delai = Future<void>.delayed(
      ref.read(dureeMinimaleDemarrageProvider),
    );
    var vue = true;
    try {
      vue = await ref.read(stockageBienvenueProvider).lireVue();
    } on Exception {
      // Lecture impossible : on ne bloque pas l'app sur la bienvenue.
    }
    await delai;
    if (!ref.mounted) return;
    state = EtatDemarrage(termine: true, bienvenueVue: vue);
  }

  Future<void> marquerBienvenueVue() async {
    state = EtatDemarrage(termine: state.termine, bienvenueVue: true);
    try {
      await ref.read(stockageBienvenueProvider).marquerVue();
    } on Exception {
      // Pas grave : l'écran pourra se réafficher au prochain lancement.
    }
  }
}
