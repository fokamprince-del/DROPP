import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'jetons.dart';

final stockageSessionProvider = Provider<StockageSession>(
  (ref) => StockageSession(const FlutterSecureStorage()),
);

/// Jetons et dernier profil connu, dans le stockage sécurisé (Keystore
/// Android / Keychain iOS). Les jetons sont aussi gardés en mémoire pour ne
/// pas relire le disque à chaque requête.
class StockageSession {
  StockageSession(this._stockage);

  static const _cleAcces = 'dropp.accessToken';
  static const _cleRefresh = 'dropp.refreshToken';
  static const _cleProfil = 'dropp.profil';

  final FlutterSecureStorage _stockage;
  Jetons? _cache;
  bool _charge = false;

  Future<Jetons?> lireJetons() async {
    if (_charge) return _cache;
    try {
      final acces = await _stockage.read(key: _cleAcces);
      final refresh = await _stockage.read(key: _cleRefresh);
      _cache = acces != null && refresh != null
          ? Jetons(accessToken: acces, refreshToken: refresh)
          : null;
    } on PlatformException {
      // Stockage illisible (clé Keystore perdue, sauvegarde restaurée…) :
      // on repart d'une session vide plutôt que de bloquer le démarrage.
      _cache = null;
      try {
        await effacer();
      } on PlatformException {
        // Rien de plus à faire : la session reste vide en mémoire.
      }
    }
    _charge = true;
    return _cache;
  }

  Future<void> ecrireJetons(Jetons jetons) async {
    _cache = jetons;
    _charge = true;
    await _stockage.write(key: _cleRefresh, value: jetons.refreshToken);
    await _stockage.write(key: _cleAcces, value: jetons.accessToken);
  }

  /// Profil de `GET /auth/me`, pour démarrer hors connexion.
  Future<Map<String, dynamic>?> lireProfil() async {
    final brut = await _stockage.read(key: _cleProfil);
    if (brut == null) return null;
    try {
      return jsonDecode(brut) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> ecrireProfil(Map<String, dynamic> profil) =>
      _stockage.write(key: _cleProfil, value: jsonEncode(profil));

  Future<void> effacer() async {
    _cache = null;
    _charge = true;
    await _stockage.delete(key: _cleAcces);
    await _stockage.delete(key: _cleRefresh);
    await _stockage.delete(key: _cleProfil);
  }
}
