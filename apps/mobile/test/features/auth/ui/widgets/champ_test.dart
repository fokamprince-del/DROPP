import 'package:dropp/features/auth/ui/widgets/champ_code.dart';
import 'package:dropp/features/auth/ui/widgets/champ_mot_de_passe.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget enfant) => MaterialApp(
  theme: ThemeDropp.clair,
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: enfant)),
);

void main() {
  testWidgets(
    'le code affiche les chiffres et signale la complétion une fois',
    (tester) async {
      final controleur = TextEditingController();
      addTearDown(controleur.dispose);
      final completes = <String>[];

      await tester.pumpWidget(
        _app(ChampCode(controleur: controleur, surComplet: completes.add)),
      );

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      expect(completes, isEmpty);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      expect(completes, ['123456']);
      expect(find.text('6'), findsOneWidget);
    },
  );

  testWidgets('le code ignore les caractères non numériques', (tester) async {
    final controleur = TextEditingController();
    addTearDown(controleur.dispose);

    await tester.pumpWidget(_app(ChampCode(controleur: controleur)));
    await tester.enterText(find.byType(TextField), '1a2b3');
    expect(controleur.text, '123');
  });

  testWidgets("l'œil bascule la visibilité du mot de passe", (tester) async {
    final controleur = TextEditingController();
    addTearDown(controleur.dispose);

    await tester.pumpWidget(_app(ChampMotDePasse(controleur: controleur)));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
  });

  testWidgets('un nouveau mot de passe affiche sa force', (tester) async {
    final controleur = TextEditingController();
    addTearDown(controleur.dispose);

    await tester.pumpWidget(
      _app(ChampMotDePasse(controleur: controleur, nouveau: true)),
    );
    await tester.enterText(find.byType(TextField), 'Abcdefg1');
    await tester.pump();

    expect(
      find.text('Solide. Ajoute un symbole pour le rendre très solide.'),
      findsOneWidget,
    );
  });
}
