import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/temps_reel/temps_reel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/icons.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/liste_paginee.dart';
import '../../../shared/widgets/messages_erreurs.dart';
import '../../../shared/widgets/vue_erreur.dart';
import '../../../utils/format.dart';
import '../application/compteur.dart';
import '../data/notifications.dart';

FaIconData _icone(TypeNotification t) => switch (t) {
  TypeNotification.commande => IconesDropp.receipt,
  TypeNotification.paiement => IconesDropp.paiement,
  TypeNotification.message => IconesDropp.messages,
  TypeNotification.social => IconesDropp.favorite,
  TypeNotification.promotion => IconesDropp.promotion,
  TypeNotification.securite => IconesDropp.securite,
  TypeNotification.systeme => IconesDropp.info,
};

/// Cloche avec pastille, pour l'en-tête de l'accueil.
class BoutonNotifications extends ConsumerWidget {
  const BoutonNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final n = ref.watch(compteurNotificationsProvider).value ?? 0;
    return IconButton(
      tooltip: n > 0 ? l10n.notificationsNonLues(n) : l10n.notificationsTitre,
      onPressed: () => unawaited(context.push<void>(Routes.notifications)),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text(n > 99 ? '99+' : '$n'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const FaIcon(IconesDropp.notification),
      ),
    );
  }
}

/// Notifications : toucher ouvre le contenu lié et la marque lue ; glisser
/// la supprime.
class PageNotifications extends ConsumerStatefulWidget {
  const PageNotifications({super.key});

  @override
  ConsumerState<PageNotifications> createState() => _PageNotificationsState();
}

class _PageNotificationsState extends ConsumerState<PageNotifications> {
  final _liste = GlobalKey<ListePagineeState<NotificationApp>>();
  StreamSubscription<Map<String, dynamic>>? _abonnement;

  NotificationsRepository get _depot =>
      ref.read(notificationsRepositoryProvider);

  @override
  void initState() {
    super.initState();
    // Une notification arrive pendant que la liste est ouverte : en tête.
    _abonnement = ref
        .read(tempsReelProvider)
        .ecouter(EvenementsTempsReel.notificationNouvelle)
        .listen((d) {
          try {
            _liste.currentState?.inserer(NotificationApp.fromJson(d));
          } on Object {
            // Forme inattendue : la liste sera juste rechargée plus tard.
          }
        });
  }

  @override
  void dispose() {
    unawaited(_abonnement?.cancel());
    super.dispose();
  }

  Future<void> _ouvrir(NotificationApp n) async {
    final destination = n.destination;
    final routeur = destination == null ? null : GoRouter.of(context);
    if (!n.lue) {
      _liste.currentState?.mettreAJour(
        (x) => x.id == n.id,
        (x) => x.copierLue(),
      );
      try {
        final restantes = await _depot.marquerLue(n.id);
        ref.read(compteurNotificationsProvider.notifier).definir(restantes);
      } on ApiException {
        // La lecture sera retentée au prochain affichage.
      }
    }
    if (destination != null) unawaited(routeur!.push<void>(destination));
  }

  Future<void> _toutLire() async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    try {
      final restantes = await _depot.toutLire();
      ref.read(compteurNotificationsProvider.notifier).definir(restantes);
      _liste.currentState?.mettreAJour((x) => !x.lue, (x) => x.copierLue());
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
    }
  }

  Future<void> _supprimer(NotificationApp n) async {
    _liste.currentState?.retirer((x) => x.id == n.id);
    try {
      await _depot.supprimer(n.id);
    } on ApiException {
      // Déjà supprimée ou hors connexion : elle reviendra au rechargement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitre),
        actions: [
          IconButton(
            tooltip: l10n.notificationsToutLire,
            onPressed: _toutLire,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: l10n.notificationsPreferences,
            onPressed: () =>
                unawaited(context.push<void>(Routes.preferencesNotifications)),
            icon: const FaIcon(IconesDropp.slider),
          ),
        ],
      ),
      body: ListePaginee<NotificationApp>(
        key: _liste,
        charger: (page) => _depot.lister(page),
        separateur: const Divider(height: 1),
        vide: EtatVide(
          icone: IconesDropp.notificationNone,
          titre: l10n.notificationsVide,
        ),
        elementBuilder: (context, n, _) => Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => unawaited(_supprimer(n)),
          background: ColoredBox(
            color: schema.error,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: Espacements.l),
                child: FaIcon(IconesDropp.delete, color: schema.onError),
              ),
            ),
          ),
          child: Semantics(
            label: n.lue ? null : l10n.notificationNonLue,
            child: ListTile(
              onTap: () => unawaited(_ouvrir(n)),
              tileColor: n.lue ? null : schema.surfaceContainerHighest,
              leading: CircleAvatar(
                backgroundColor: schema.primary.withValues(alpha: 0.12),
                child: FaIcon(_icone(n.type), color: schema.primary, size: 20),
              ),
              title: Text(
                n.titre,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: n.lue ? FontWeight.w500 : FontWeight.w800,
                ),
              ),
              subtitle: Text(
                n.contenu,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                tempsRelatif(l10n, n.dateCreation),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: schema.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String libelleTypeNotification(AppLocalizations l10n, TypeNotification t) =>
    switch (t) {
      TypeNotification.message => l10n.preferenceMessages,
      TypeNotification.social => l10n.preferenceSocial,
      TypeNotification.promotion => l10n.preferencePromotions,
      _ => t.valeur,
    };

final _preferencesProvider =
    FutureProvider.autoDispose<Map<TypeNotification, bool>>(
      (ref) => ref.watch(notificationsRepositoryProvider).preferences(),
    );

/// Push par type : messages, activité sociale, promotions. Les commandes,
/// paiements et alertes de sécurité restent toujours envoyés.
class PagePreferencesNotifications extends ConsumerStatefulWidget {
  const PagePreferencesNotifications({super.key});

  @override
  ConsumerState<PagePreferencesNotifications> createState() =>
      _PagePreferencesNotificationsState();
}

class _PagePreferencesNotificationsState
    extends ConsumerState<PagePreferencesNotifications> {
  Map<TypeNotification, bool>? _local;

  Future<void> _basculer(TypeNotification type, bool active) async {
    final l10n = context.l10n;
    final messager = ScaffoldMessenger.of(context);
    final avant = _local;
    setState(() => _local = {...?_local, type: active});
    try {
      final aJour = await ref
          .read(notificationsRepositoryProvider)
          .modifierPreference(type, active: active);
      if (mounted) setState(() => _local = aJour);
    } on ApiException catch (e) {
      if (mounted) setState(() => _local = avant);
      messager.showSnackBar(SnackBar(content: Text(messageErreurApi(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final etat = ref.watch(_preferencesProvider);
    final preferences = _local ?? etat.value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsPreferences)),
      body: preferences == null
          ? Center(
              child: etat.hasError
                  ? VueErreur(
                      erreur: ApiException.depuis(etat.error!),
                      reessayer: () => ref.invalidate(_preferencesProvider),
                    )
                  : const CircularProgressIndicator(),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Espacements.l),
                  child: Text(
                    l10n.preferencesExplication,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final type in typesConfigurables)
                  SwitchListTile(
                    title: Text(libelleTypeNotification(l10n, type)),
                    value: preferences[type] ?? true,
                    onChanged: (v) => unawaited(_basculer(type, v)),
                  ),
              ],
            ),
    );
  }
}
