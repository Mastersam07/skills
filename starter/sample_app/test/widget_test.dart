import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app/main.dart';

void main() {
  testWidgets('shows the empty home screen', (tester) async {
    await tester.pumpWidget(const SampleApp());
    expect(find.text('MoshoTopUp Demo'), findsOneWidget);
  });
}
