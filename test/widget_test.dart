
import 'package:flutter_test/flutter_test.dart';
import 'package:agriguide/main.dart';

void main() {
  testWidgets('AgriGuide app launches successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AgriGuideApp());

    // Allow the initial app frame to render.
    await tester.pump();

    // Verify that the application launches.
    expect(find.byType(AgriGuideApp), findsOneWidget);
  });
}
