// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:doan/main.dart';

void main() {
  testWidgets('FoodDeliveryApp renders navigation', (WidgetTester tester) async {
    // Build our FoodDeliveryApp and trigger a frame.
    await tester.pumpWidget(const FoodDeliveryApp());
    await tester.pump();

    // Verify that the app renders the discovery navigation label
    expect(find.text('Khám Phá'), findsOneWidget);
  });
}
