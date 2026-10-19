import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_it/app.dart';

void main() {
  testWidgets('Cosmo Pop app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CosmoApp());
    expect(find.byType(CosmoApp), findsOneWidget);
  });
}
