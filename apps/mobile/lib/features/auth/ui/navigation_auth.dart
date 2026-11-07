import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';

/// Reporte `?de=` (page demandée avant la connexion) d'un écran d'accès à
/// l'autre, pour y revenir une fois connecté.
String cheminAvecRetour(BuildContext context, String cible) {
  final retour = GoRouterState.of(context)
      .uri
      .queryParameters[Routes.parametreRetour];
  if (retour == null) return cible;
  return Uri(
    path: cible,
    queryParameters: {Routes.parametreRetour: retour},
  ).toString();
}
