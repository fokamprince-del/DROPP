import 'package:dropp/features/auth/ui/widgets/bouton_google.dart';
import 'package:dropp/features/auth/ui/widgets/separateur_ou.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:dropp/shared/widgets/message_temporaire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget enfant) => MaterialApp(
      theme: ThemeDropp.clair,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: enfant)),
    );

void main() {
  testWidgets('le bouton affiche son libellé et signale l\'appui',
      (tester) async {
    var appuis = 0;
    await tester.pumpWidget(
      _app(BoutonGoogle(libelle: 'Se connecter avec Google', surAppui: () => appuis++)),
    );

    await tester.tap(find.text('Se connecter avec Google'));
    expect(appuis, 1);
  });

  testWidgets('le séparateur affiche « ou »', (tester) async {
    await tester.pumpWidget(_app(const SeparateurOu()));
    expect(find.text('ou'), findsOneWidget);
  });

  testWidgets('le message temporaire apparaît puis se remplace', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => afficherMessageTemporaire(context, 'Premier'),
            child: const Text('Aller'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aller'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Premier'), findsOneWidget);
  });
}