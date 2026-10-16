import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosho_topup/mosho_topup.dart';
import 'package:sample_app/buy_data_screen.dart';

void main() {
  testWidgets('loads MTN plans and enables buying once a plan is chosen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BuyDataScreen(
          client: MoshoTopUp(apiKey: 'test_mosho_123', latency: Duration.zero),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('1GB'), findsOneWidget);
    expect(find.text('Choose a plan'), findsNWidgets(2));

    await tester.tap(find.text('1GB'));
    await tester.pump();

    expect(find.text('Buy 1GB for ₦1,000'), findsOneWidget);
  });
}
