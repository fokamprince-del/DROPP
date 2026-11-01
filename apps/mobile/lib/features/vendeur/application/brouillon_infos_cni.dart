import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../data/modeles_kyc.dart';
import '../domain/formulaire_cni.dart';

/// Saisie en cours, gardée EN MÉMOIRE quand on quitte l'écran (retour à
/// l'étape précédente). Jamais écrite sur disque. Repart de zéro quand
/// l'utilisateur change.
final brouillonInfosCniProvider =
    NotifierProvider<BrouillonInfosCniNotifier, FormulaireCni>(
      BrouillonInfosCniNotifier.new,
    );

class BrouillonInfosCniNotifier extends Notifier<FormulaireCni> {
  @override
  FormulaireCni build() {
    ref.watch(utilisateurConnecteProvider.select((u) => u?.id));
    return const FormulaireCni();
  }

  void modifier(ChampCni champ, String valeur) =>
      state = state.avec(champ, valeur);

  void appliquerExtraction(DonneesCni donnees) =>
      state = state.avecExtraction(donnees);

  /// Données déjà enregistrées côté serveur.
  void initialiser(DonneesCni donnees) =>
      state = FormulaireCni.depuisDonnees(donnees);

  void vider() => state = const FormulaireCni();
}
