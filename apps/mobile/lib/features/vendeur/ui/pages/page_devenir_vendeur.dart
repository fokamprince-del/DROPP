import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/l10n/contexte_l10n.dart';
import '../../../../shared/theme/espacements.dart';
import '../../../../shared/widgets/bandeau_message.dart';
import '../../../../shared/widgets/bouton_action.dart';
import '../../../../shared/widgets/messages_erreurs.dart';
import '../../../../shared/widgets/page_acces.dart';
import '../../data/vendeur_repository.dart';
import 'reprendre_dossier_kyc.dart';

class PageDevenirVendeur extends ConsumerStatefulWidget {
  const PageDevenirVendeur({super.key});

  @override
  ConsumerState<PageDevenirVendeur> createState() => _PageDevenirVendeurState();
}

class _PageDevenirVendeurState extends ConsumerState<PageDevenirVendeur> {
  bool _envoi = false;
  String? _erreur;
  String? _cleIdempotence;

  Future<void> _commencer() async {
    if (_envoi) return;
    final l10n = context.l10n;
    final depot = ref.read(vendeurRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final cle = _cleIdempotence ??= const Uuid().v4();

    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await depot.devenirVendeur(cleIdempotence: cle);
      _cleIdempotence = null;
      await session.rafraichirProfil();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = messageErreurApi(l10n, e));
      // Le profil vendeur existe peut-être déjà côté serveur.
      if (e.type == TypeErreurApi.conflit) await session.rafraichirProfil();
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    if (utilisateur == null) return const Scaffold();

        if (utilisateur.estVendeur) {
      if (utilisateur.statutVendeur == 'SUSPENDU') {
        return PageAcces(
          titre: l10n.vendeurTitre,
          enfants: [BandeauMessage(message: l10n.vendeurSuspendu)],
        );
      }
      return PageAcces(
        titre: l10n.vendeurTitre,
        enfants: const [ReprendreDossierKyc()],
      );
    }

    return PageAcces(
      titre: l10n.vendeurTitre,
      sousTitre: l10n.vendeurIntro,
      enfants: [
        if (_erreur != null) ...[
          BandeauMessage(message: _erreur!),
          const SizedBox(height: Espacements.l),
        ],
        Text(
          l10n.vendeurPrerequisTitre,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Espacements.s),
        _Prerequis(
          libelle: l10n.vendeurPrerequisTelephone,
          acquis: utilisateur.telephoneVerifie,
        ),
        _Prerequis(libelle: l10n.vendeurPrerequisCni),
        _Prerequis(libelle: l10n.vendeurPrerequisSelfie),
        const SizedBox(height: Espacements.m),
        Text(l10n.vendeurDelai, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Espacements.xl),
        BoutonAction(
          libelle: l10n.vendeurCommencer,
          enCours: _envoi,
          surAppui: _commencer,
        ),
      ],
    );
  }
}

class _Prerequis extends StatelessWidget {
  const _Prerequis({required this.libelle, this.acquis = false});

  final String libelle;
  final bool acquis;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacements.xs),
      child: Row(
        children: [
          Icon(
            acquis ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: acquis ? schema.primary : schema.outline,
          ),
          const SizedBox(width: Espacements.s),
          Expanded(child: Text(libelle)),
        ],
      ),
    );
  }
}
