import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise que l'écran de bienvenue a déjà été vu sur cet appareil.
/// Interface séparée pour pouvoir la remplacer dans les tests.
abstract interface class StockageBienvenue {
  Future<bool> lireVue();
  Future<void> marquerVue();
}

class StockageBienvenuePreferences implements StockageBienvenue {
  StockageBienvenuePreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _cle = 'dropp.bienvenue_vue';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> lireVue() async => (await _preferences.getBool(_cle)) ?? false;

  @override
  Future<void> marquerVue() => _preferences.setBool(_cle, true);
}

final stockageBienvenueProvider = Provider<StockageBienvenue>(
  (ref) => StockageBienvenuePreferences(),
);
