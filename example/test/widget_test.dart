import 'package:flutter_test/flutter_test.dart';

import 'package:chainway_rfid_scanner_example/main.dart';

void main() {
  testWidgets('shows the R2 test application', (WidgetTester tester) async {
    await tester.pumpWidget(const R2TestApp());
    await tester.pump();

    expect(find.text('Chainway R2 Test App'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
  });
}
