import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/session.dart';
import '../../../core/l10n/contexte_l10n.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/messages_erreurs.dart';

/// `true` si l'utilisateur est connecté. Sinon ouvre la connexion, qui
/// ramènera sur la page actuelle, et renvoie `false`.
bool exigerConnexion(BuildContext context, WidgetRef ref) {
  if (ref.read(utilisateurConnecteProvider) != null) return true;
  final routeur = GoRouter.of(context);
  final ici = routeur.routerDelegate.currentConfiguration.uri.toString();
  unawaited(
    routeur.push<void>(
      Uri(
        path: Routes.connexion,
        queryParameters: {Routes.parametreRetour: ici},
      ).toString(),
    ),
  );
  return false;
}

/// Exige la connexion, lance [action] et affiche l'éventuelle erreur de
/// l'API en bas de l'écran.
Future<void> actionConnectee(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  if (!exigerConnexion(context, ref)) return;
  final messager = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  try {
    await action();
  } on ApiException catch (e) {
    messager
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            messageErreurApi(
              l10n,
              e,
              specifiques: {
                TypeErreurApi.interdit: l10n.erreurActionInterdite,
                TypeErreurApi.introuvable: l10n.erreurContenuIntrouvable,
              },
            ),
          ),
        ),
      );
  }
}
