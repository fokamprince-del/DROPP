import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

bool ouvertDepuisRecapitulatif(BuildContext context) =>
    GoRouterState.of(context).uri.queryParameters['depuis'] == 'recap';

/// Passe à l'étape suivante, ou revient au récapitulatif si l'on en vient.
void continuerVers(BuildContext context, String suivante) {
  if (ouvertDepuisRecapitulatif(context)) {
    context.pop();
  } else {
    unawaited(context.push<void>(suivante));
  }
}
