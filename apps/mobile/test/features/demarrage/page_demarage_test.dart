import 'package:dropp/features/demarrage/page_demarrage.dart';
import 'package:dropp/l10n/app_localizations.dart';
import 'package:dropp/shared/theme/theme_dropp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('affiche le logo et l’accroche', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeDropp.clair,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PageDemarrage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DROPP', findRichText: true), findsOneWidget);
    expect(find.text('Le marché camerounais dans ta poche'), findsOneWidget);
  });
}
