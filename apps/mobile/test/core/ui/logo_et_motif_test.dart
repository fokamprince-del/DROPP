import 'package:dropp/core/ui/logo_dropp.dart';
import 'package:dropp/core/ui/motif_ndop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('le motif occupe la hauteur demandée', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MotifNdop(
            hauteur: 24,
            couleurFonce: Colors.indigo,
            couleurClair: Colors.white,
          ),
        ),
      ),
    );
    final taille = tester.getSize(find.byType(MotifNdop));
    expect(taille.height, 24);
    expect(taille.width, 800); // pleine largeur disponible
  });

  testWidgets('le logo affiche DROPP une fois animé', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: LogoDropp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DROPP', findRichText: true), findsOneWidget);
  });

  testWidgets('le logo est exposé comme DROPP aux lecteurs d’écran',
      (tester) async {
    final poignee = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: LogoDropp(anime: false),
      ),
    );
    expect(find.bySemanticsLabel('DROPP'), findsOneWidget);
    poignee.dispose();
  });
}