import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('Renders VectorStoreExampleApp and controls', (tester) async {
    await tester.pumpWidget(const VectorStoreExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Flutter Vector Store'), findsOneWidget);
    expect(find.text('2D Vector Projection Space'), findsOneWidget);
    expect(find.text('Agriculture'), findsWidgets);
  });
}
