import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../auth/jetons.dart';
import '../auth/session.dart';

/// Connexion minimale pour tester le socle avant les vrais écrans d'auth de
/// Dev B. À supprimer quand `Routes.connexion` pointe sur l'écran final.
class ConnexionDevPage extends ConsumerStatefulWidget {
  const ConnexionDevPage({super.key});

  @override
  ConsumerState<ConnexionDevPage> createState() => _ConnexionDevPageState();
}

class _ConnexionDevPageState extends ConsumerState<ConnexionDevPage> {
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final reponse = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
        '/auth/connexion',
        data: {
          'identifiant': _identifiant.text.trim(),
          'motDePasse': _motDePasse.text,
        },
      );
      if (reponse['verificationRequise'] == true) {
        setState(() => _erreur = 'Compte non vérifié : passer par l\'inscription.');
        return;
      }
      // La redirection du routeur emmène ensuite vers la page demandée.
      await ref.read(sessionProvider.notifier).ouvrir(Jetons.fromJson(reponse));
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion (dev)')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (session case SessionAnonyme(expiree: true))
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Votre session a expiré. Reconnectez-vous.'),
            ),
          TextField(
            controller: _identifiant,
            decoration: const InputDecoration(labelText: 'Téléphone ou email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _motDePasse,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          if (_erreur != null)
            Text(_erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _envoi ? null : _connecter,
            child: Text(_envoi ? 'Connexion…' : 'Se connecter'),
          ),
        ],
      ),
    );
  }
}
