import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nofak/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap fab test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    
    await tester.tap(fab);
    await tester.pumpAndSettle();
    
    print("SUCCESSFULLY TAPPED");
  });
}
