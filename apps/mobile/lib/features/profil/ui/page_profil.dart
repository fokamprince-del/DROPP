import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/upload/choix_media.dart';
import '../../../core/upload/service_upload.dart';
import '../../../shared/theme/couleurs_metier.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/theme/typographie.dart';
import '../../../shared/widgets/avatar_boutique.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/squelette.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../auth/ui/pages/page_confirmation_email.dart';
import '../data/profil.dart';

/// Onglet Profil : photo, identité, puis accès à tout ce qui concerne le
/// compte (achats, social, sécurité, vendeur).
class PageProfil extends ConsumerStatefulWidget {
  const PageProfil({super.key});

  @override
  ConsumerState<PageProfil> createState() => _PageProfilState();
}

class _PageProfilState extends ConsumerState<PageProfil> {
  /// Progression de l'envoi de la photo, ou `null`.
  double? _progression;

  Future<void> _changerPhoto() async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    final depot = ref.read(profilRepositoryProvider);
    try {
      final fichier = await choisirMedia(
        context,
        video: false,
        tailleMaxImageMo: tailleMaxPhotoProfilMo,
      );
      if (fichier == null || !mounted) return;
      setState(() => _progression = 0);
      await ref
          .read(serviceUploadProvider)
          .envoyer(
            fichier,
            demanderSignature: depot.signaturePhoto,
            confirmer: (envoye) => depot.confirmerPhoto(envoye.cleStockage),
            surProgression: (p) {
              if (mounted) setState(() => _progression = p);
            },
          );
      ref.invalidate(profilProvider);
    } on FichierRefuse catch (e) {
      messager.showSnackBar(
        SnackBar(
          content: Text(
            e.tropGros
                ? l10n.fichierTropGros(e.tailleMaxMo ?? tailleMaxPhotoProfilMo)
                : l10n.fichierFormatRefuse,
          ),
        ),
      );
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
    } finally {
      if (mounted) setState(() => _progression = null);
    }
  }

  Future<void> _retirerPhoto() async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    try {
      await ref.read(profilRepositoryProvider).supprimerPhoto();
      ref.invalidate(profilProvider);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
    }
  }

  Future<void> _deconnecter() async {
    final l10n = context.l10n;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deconnexionTitre),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.annuler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deconnexion),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await ref.read(sessionProvider.notifier).deconnecter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final etat = ref.watch(profilProvider);
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    final profil = etat.value;

    if (profil == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navProfil)),
        body: etat.hasError
            ? Center(
                child: VueErreur(
                  erreur: ApiException.depuis(etat.error!),
                  reessayer: () => ref.invalidate(profilProvider),
                ),
              )
            : const Padding(
                padding: EdgeInsets.all(Espacements.l),
                child: Column(
                  children: [
                    Squelette(largeur: 88, hauteur: 88, cercle: true),
                    SizedBox(height: Espacements.m),
                    Squelette(largeur: 160, hauteur: 16),
                  ],
                ),
              ),
      );
    }

    void aller(String route) => unawaited(context.push<void>(route));
    Widget entree(
      FaIconData icone,
      String titre,
      VoidCallback surAppui, {
      String? sousTitre,
    }) => ListTile(
      leading: FaIcon(icone),
      title: Text(titre),
      subtitle: sousTitre == null ? null : Text(sousTitre),
      trailing: const Icon(Icons.chevron_right),
      onTap: surAppui,
    );
    Widget section(String titre) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacements.l,
        Espacements.l,
        Espacements.l,
        Espacements.xs,
      ),
      child: Text(
        titre,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final emailEtat = profil.email == null
        ? l10n.profilEmailAbsent
        : (utilisateur?.emailVerifie ?? false)
        ? profil.email!
        : l10n.profilEmailAConfirmer(profil.email!);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfil)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(profilProvider),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Espacements.xl),
          children: [
            const SizedBox(height: Espacements.s),
            Center(
              child: Stack(
                children: [
                  AvatarBoutique(
                    nom: profil.nomComplet,
                    logoUrl: profil.photoUrl,
                    taille: 88,
                  ),
                  if (_progression != null)
                    Positioned.fill(
                      child: CircularProgressIndicator(value: _progression),
                    ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: PopupMenuButton<bool>(
                      tooltip: l10n.profilPhoto,
                      enabled: _progression == null,
                      onSelected: (changer) => unawaited(
                        changer ? _changerPhoto() : _retirerPhoto(),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: true,
                          child: Text(l10n.profilChangerPhoto),
                        ),
                        if (profil.photoUrl != null)
                          PopupMenuItem(
                            value: false,
                            child: Text(l10n.profilRetirerPhoto),
                          ),
                      ],
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: FaIcon(
                          IconesDropp.photo,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Espacements.m),
            Text(
              profil.nomComplet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: Typographie.titre,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              profil.pseudo == null
                  ? l10n.profilSansPseudo
                  : '@${profil.pseudo}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (profil.telephone != null)
              Text(
                profil.telephone!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: Espacements.s),
            Center(
              child: OutlinedButton(
                onPressed: () => aller(Routes.modifierProfil),
                child: Text(l10n.profilModifier),
              ),
            ),
            section(l10n.profilSectionAchats),
            entree(
              IconesDropp.receipt,
              l10n.commandesTitre,
              () => aller(Routes.commandes),
            ),
            entree(
              IconesDropp.location,
              l10n.adressesTitre,
              () => aller(Routes.adresses),
            ),
            entree(
              IconesDropp.solidStar,
              l10n.avisANoterTitre,
              () => aller(Routes.avisANoter),
            ),
            section(l10n.profilSectionSocial),
            entree(
              IconesDropp.solidBookmark,
              l10n.favorisTitre,
              () => aller(Routes.mesFavoris),
            ),
            entree(
              IconesDropp.shop,
              l10n.abonnementsTitre,
              () => aller(Routes.mesAbonnements),
            ),
            section(l10n.profilSectionCompte),
            entree(
              IconesDropp.emailAt,
              l10n.profilEmail,
              () => ouvrirConfirmationEmail(context),
              sousTitre: emailEtat,
            ),
            entree(
              IconesDropp.securite,
              l10n.securiteTitre,
              () => aller(Routes.securite),
            ),
            entree(
              IconesDropp.notification,
              l10n.notificationsPreferences,
              () => aller(Routes.preferencesNotifications),
            ),
            entree(
              IconesDropp.ban,
              l10n.bloquesTitre,
              () => aller(Routes.bloques),
            ),
            entree(
              IconesDropp.solidFlag,
              l10n.signalementsTitre,
              () => aller(Routes.mesSignalements),
            ),
            section(l10n.profilSectionVendeur),
            if (utilisateur?.estVendeur ?? false)
              entree(
                IconesDropp.storeFront,
                l10n.profilEspaceVendeur,
                () => aller(Routes.espaceVendeur),
              )
            else
              entree(
                IconesDropp.vendeur,
                l10n.profilDevenirVendeur,
                () => aller(Routes.devenirVendeur),
              ),
            const SizedBox(height: Espacements.l),
            Center(
              child: TextButton.icon(
                onPressed: _deconnecter,
                style: TextButton.styleFrom(
                  foregroundColor: context.couleursMetier.erreur,
                ),
                icon: const FaIcon(IconesDropp.logout),
                label: Text(l10n.deconnexion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
