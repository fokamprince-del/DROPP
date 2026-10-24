import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ObjectifVerification { activation, reinitialisation }

@immutable
class FluxVerification {
  const FluxVerification({
    required this.objectif,
    required this.verificationToken,
    required this.identifiant,
  });

  final ObjectifVerification objectif;
  final String verificationToken;

  /// Téléphone international (activation) ou identifiant saisi (réinitialisation).
  final String identifiant;

  FluxVerification avecToken(String token) => FluxVerification(
    objectif: objectif,
    verificationToken: token,
    identifiant: identifiant,
  );
}

final fluxVerificationProvider =
    NotifierProvider<FluxVerificationNotifier, FluxVerification?>(
      FluxVerificationNotifier.new,
    );

class FluxVerificationNotifier extends Notifier<FluxVerification?> {
  @override
  FluxVerification? build() => null;

  void demarrer(FluxVerification flux) => state = flux;

  void remplacerToken(String token) {
    final flux = state;
    if (flux != null) state = flux.avecToken(token);
  }

  void terminer() => state = null;
}
