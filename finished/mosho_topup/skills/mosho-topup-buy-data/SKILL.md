---
name: mosho-topup-buy-data
description: Use when writing code that buys data or airtime with the mosho_topup package, including phone number handling, fetching plans, showing prices, and handling pending or failed top-ups.
---

# Buying data with mosho_topup

mosho_topup buys airtime and data for Nigerian phone numbers. Create one `MoshoTopUp` client and reuse it.

## Rules

- Always pass phone numbers through `normalizeNigerianPhone()` before calling the SDK. Never pass raw user input like `08031234567`. It throws a `FormatException` for invalid numbers; show that to the user as a validation error.
- Always load plans with `topup.plans(network: ...)`. Never hardcode plan names, sizes, prices, or plan IDs.
- All amounts are in kobo. Display prices with `formatNaira(plan.amountInKobo)`. Never divide or format kobo yourself.
- `buyData` returns a sealed `TopUpResult`. Use an exhaustive `switch` on `TopUpSuccess`, `TopUpPending`, and `TopUpFailed`. Failures are results, not exceptions, so do not rely on try/catch for them.
- `TopUpPending` is not a failure. Tell the user the purchase is processing and poll `topup.status(reference)` every few seconds, up to about 10 times.
- Create one reference per purchase with `newReference()`. If a call throws or the result is still pending, retry or check again with that same reference. Only create a new reference for a new purchase: after `TopUpFailed`, or when the phone number or plan changes. A new reference creates a new charge.

## Example

```dart
import 'package:mosho_topup/mosho_topup.dart';

final topup = MoshoTopUp(apiKey: 'test_mosho_123');

Future<TopUpResult> buyPlan(String rawPhone, DataPlan plan) async {
  final phone = normalizeNigerianPhone(rawPhone);
  final reference = newReference();

  var result = await topup.buyData(
    phone: phone,
    planId: plan.id,
    reference: reference,
  );

  for (var attempt = 0; result is TopUpPending && attempt < 10; attempt++) {
    await Future.delayed(const Duration(seconds: 3));
    result = await topup.status(reference);
  }

  return result;
}

String describe(TopUpResult result) => switch (result) {
      TopUpSuccess() => 'Data delivered!',
      TopUpPending() => 'Still processing. We will keep checking.',
      TopUpFailed(:final message) => 'Failed: $message',
    };
```

## Do not

- Do not hardcode plans like "1GB for ₦1,000".
- Do not show `amountInKobo` directly as a naira price.
- Do not treat `TopUpPending` as an error.
- Do not call `newReference()` again when retrying after an error or a pending result.
