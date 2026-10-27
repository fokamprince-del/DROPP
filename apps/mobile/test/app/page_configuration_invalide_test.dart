import 'package:dropp/app/page_configuration_invalide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('une API_URL refusée affiche DROPP et l’erreur, pas un écran '
      'blanc', (tester) async {
    await tester.pumpWidget(
      const PageConfigurationInvalide(
        message: 'API_URL doit être en https en release : "http://x"',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('DROPP'), findsOneWidget);
    expect(find.text('Application mal configurée'), findsOneWidget);
    expect(find.textContaining('https en release'), findsOneWidget);
  });
}
