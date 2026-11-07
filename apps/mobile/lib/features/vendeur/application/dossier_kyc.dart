import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kyc_repository.dart';
import '../data/modeles_kyc.dart';

/// `retry` désactivé : Riverpod 3 relance sinon automatiquement un provider en
/// erreur, ce qui multiplierait les appels sur un 403.
final dossierKycProvider = FutureProvider.autoDispose<DossierKyc?>(
  (ref) => ref.watch(kycRepositoryProvider).monDossier(),
  retry: (_, _) => null,
);
