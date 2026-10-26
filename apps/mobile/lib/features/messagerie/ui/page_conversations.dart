import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/temps_reel/temps_reel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/espacements.dart';
import '../../../shared/theme/typographie.dart';
import '../../../shared/widgets/avatar_boutique.dart';
import '../../../shared/widgets/etat_vide.dart';
import '../../../shared/widgets/liste_paginee.dart';
import '../../../utils/format.dart';
import '../application/non_lus.dart';
import '../data/messagerie.dart';

/// Aperçu d'un message : son texte, ou « Photo », « Vidéo »…
String apercuMessage(AppLocalizations l10n, Message m) {
  final texte = m.contenu?.trim();
  if (texte != null && texte.isNotEmpty) return texte;
  return switch (m.type) {
    TypeMessage.image => l10n.messagePhoto,
    TypeMessage.video => l10n.messageVideo,
    _ => l10n.messagePieceJointe,
  };
}

/// Onglet Messages : conversations, les plus actives d'abord.
class PageConversations extends ConsumerStatefulWidget {
  const PageConversations({super.key});

  @override
  ConsumerState<PageConversations> createState() => _PageConversationsState();
}

class _PageConversationsState extends ConsumerState<PageConversations> {
  final _liste = GlobalKey<ListePagineeState<Conversation>>();
  StreamSubscription<Map<String, dynamic>>? _abonnement;
  Timer? _rechargement;

  @override
  void initState() {
    super.initState();
    // Nouveau message : la conversation remonte, son aperçu change. Les
    // rafales de messages ne déclenchent qu'un rechargement.
    _abonnement = ref
        .read(tempsReelProvider)
        .ecouter(EvenementsTempsReel.messageNouveau)
        .listen((_) {
          _rechargement?.cancel();
          _rechargement = Timer(const Duration(seconds: 1), () {
            if (mounted) unawaited(_liste.currentState?.recharger());
          });
        });
  }

  @override
  void dispose() {
    unawaited(_abonnement?.cancel());
    _rechargement?.cancel();
    super.dispose();
  }

  Future<void> _ouvrir(Conversation c) async {
    await context.push<void>(Routes.conversation(c.id), extra: c);
    // Au retour : messages lus, nouvel aperçu, nouvel ordre.
    if (!mounted) return;
    unawaited(_liste.currentState?.recharger());
    ref.read(nonLusProvider.notifier).rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final moi = ref.watch(utilisateurConnecteProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacements.l,
                Espacements.s,
                Espacements.l,
                Espacements.s,
              ),
              child: Text(
                l10n.navMessages,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: Typographie.titre,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListePaginee<Conversation>(
                key: _liste,
                charger: ref.read(messagerieRepositoryProvider).lister,
                auRafraichir: () async =>
                    ref.read(nonLusProvider.notifier).rafraichir(),
                vide: EtatVide(
                  icone: Icons.chat_bubble_outline,
                  titre: l10n.conversationsVide,
                  texte: l10n.conversationsVideTexte,
                ),
                elementBuilder: (context, c, _) => _TuileConversation(
                  conversation: c,
                  moiId: moi?.id,
                  surAppui: () => _ouvrir(c),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TuileConversation extends StatelessWidget {
  const _TuileConversation({
    required this.conversation,
    required this.moiId,
    required this.surAppui,
  });

  final Conversation conversation;
  final String? moiId;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final c = conversation;
    final nom = c.interlocuteur?.nomAffiche ?? l10n.conversationCompteSupprime;
    final dernier = c.dernierMessage;
    final nonLu = c.nonLus > 0;
    final apercu = dernier == null
        ? ''
        : dernier.expediteurId == moiId
        ? l10n.messageDeMoi(apercuMessage(l10n, dernier))
        : apercuMessage(l10n, dernier);

    return InkWell(
      onTap: surAppui,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Espacements.l,
          vertical: 10,
        ),
        child: Row(
          children: [
            AvatarBoutique(
              nom: nom,
              logoUrl: c.interlocuteur?.imageUrl,
              taille: 48,
            ),
            const SizedBox(width: Espacements.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    apercu,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: nonLu ? schema.onSurface : schema.onSurfaceVariant,
                      fontWeight: nonLu ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Espacements.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tempsRelatif(l10n, c.dateDerniereActivite),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: schema.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                if (nonLu)
                  Badge(
                    label: Text(c.nonLus > 99 ? '99+' : '${c.nonLus}'),
                    backgroundColor: schema.secondary,
                    textColor: schema.onSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
