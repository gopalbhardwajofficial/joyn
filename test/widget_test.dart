import 'package:flutter_test/flutter_test.dart';
import 'package:joyn/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const JoynApp());
    expect(find.byType(JoynApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2100));
  });
}
