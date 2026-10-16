import 'package:mosho_topup/mosho_topup.dart';

Future<void> main() async {
  final topup = MoshoTopUp(apiKey: 'test_mosho_123');

  final plans = await topup.plans(network: Network.mtn);
  for (final plan in plans) {
    print('${plan.name} · ${plan.validityDays} days · ${formatNaira(plan.amountInKobo)}');
  }

  final reference = newReference();
  var result = await topup.buyData(
    phone: normalizeNigerianPhone('0803 123 4560'),
    planId: plans[1].id,
    reference: reference,
  );

  for (var check = 0; result is TopUpPending && check < 10; check++) {
    print('Still processing, checking again...');
    await Future<void>.delayed(const Duration(seconds: 1));
    result = await topup.status(reference);
  }

  print(switch (result) {
    TopUpSuccess(:final plan, :final phone) => '${plan.name} delivered to $phone',
    TopUpPending() => 'Still processing. Check again later with the same reference.',
    TopUpFailed(:final message) => 'Failed: $message',
  });
}
