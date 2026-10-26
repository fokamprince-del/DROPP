import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/contexte_l10n.dart';
import '../../core/router/routes.dart';
import '../../shared/theme/espacements.dart';
import 'demarrage.dart';
import 'illustration_bienvenue.dart';

class PageBienvenue extends ConsumerStatefulWidget {
  const PageBienvenue({super.key});

  @override
  ConsumerState<PageBienvenue> createState() => _PageBienvenueState();
}

class _PageBienvenueState extends ConsumerState<PageBienvenue> {
  final _controleur = PageController();
  int _index = 0;

  static const _icones = [
    [
      Icons.checkroom_outlined,
      Icons.smartphone_outlined,
      Icons.storefront_outlined,
    ],
    [
      Icons.chat_bubble_outline,
      Icons.help_outline,
      Icons.local_shipping_outlined,
    ],
    [
      Icons.account_balance_wallet_outlined,
      Icons.lock_outline,
      Icons.verified_outlined,
    ],
  ];

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  /// L'accueil reste dessous : le bouton retour y ramène, car l'app se
  /// consulte sans compte.
  Future<void> _continuer(String destination) async {
    final routeur = GoRouter.of(context);
    await ref.read(demarrageProvider.notifier).marquerBienvenueVue();
    routeur.go(Routes.accueil);
    unawaited(routeur.push<void>(destination));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final titres = [
      l10n.bienvenue1Titre,
      l10n.bienvenue2Titre,
      l10n.bienvenue3Titre,
    ];
    final textes = [
      l10n.bienvenue1Texte,
      l10n.bienvenue2Texte,
      l10n.bienvenue3Texte,
    ];

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Espacements.xl),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controleur,
                      itemCount: titres.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: Espacements.xl),
                            IllustrationBienvenue(icones: _icones[i]),
                            const SizedBox(height: Espacements.xl),
                            Text(
                              titres[i],
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: Espacements.s),
                            Text(
                              textes[i],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    label: l10n.bienvenuePage(_index + 1, titres.length),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < titres.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(Espacements.xs),
                              width: i == _index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i == _index
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Espacements.l),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _continuer(Routes.inscription),
                      child: Text(l10n.creerUnCompte),
                    ),
                  ),
                  const SizedBox(height: Espacements.m),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _continuer(Routes.connexion),
                      child: Text(l10n.jaiDejaUnCompte),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
