import 'package:background_remover/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen shows the app title and select action', (tester) async {
    await tester.pumpWidget(const BackgroundRemoverApp());

    expect(find.text('Background Remover'), findsOneWidget);
    expect(find.text('Select Image'), findsOneWidget);
  });
}
