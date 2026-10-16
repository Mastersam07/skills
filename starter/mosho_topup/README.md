# mosho_topup

A tiny SDK for buying data and airtime for Nigerian phone numbers.

> This package was built for the **"Your Next User Is an Agent: Shipping Skills With Your SDK"** workshop. It runs against a fake, in-memory backend, so it works offline and never charges anyone.

## Install

```yaml
dependencies:
  mosho_topup:
    path: ../mosho_topup
```

## Quick start

```dart
import 'package:mosho_topup/mosho_topup.dart';

final topup = MoshoTopUp(apiKey: 'test_mosho_123');

final plans = await topup.plans(network: Network.mtn);

final reference = newReference();
final result = await topup.buyData(
  phone: normalizeNigerianPhone('0803 123 4567'),
  planId: plans.first.id,
  reference: reference,
);

switch (result) {
  case TopUpSuccess(:final plan):
    print('${plan.name} delivered');
  case TopUpPending():
    print('Processing. Check again with topup.status(reference)');
  case TopUpFailed(:final message):
    print(message);
}
```

## Rules

**Phone numbers must be in `+234` format.** `buyData` throws an `ArgumentError` for anything else. Use `normalizeNigerianPhone()` on whatever the user typed. It accepts `0803 123 4567`, `2348031234567` and `+234 803 123 4567`, and throws a `FormatException` for invalid numbers.

**Always load plans with `plans(network: ...)`.** Plans and prices change. Plan IDs are opaque, so a hardcoded ID will fail.

**Amounts are in kobo.** ₦1 is 100 kobo, so a 1GB plan priced at ₦1,000 has `amountInKobo: 100000`. Show prices with `formatNaira(plan.amountInKobo)`.

**`buyData` returns a sealed `TopUpResult`.** Handle all three cases with a `switch`: `TopUpSuccess`, `TopUpPending` and `TopUpFailed`. Failures are results, not exceptions.

**Pending is not failed.** Networks are often slow to confirm. When you get `TopUpPending`, poll `status(reference)` every few seconds.

**References make purchases safe to retry.** Create one reference per purchase with `newReference()`. If a call throws or the purchase is still pending, retry with the **same** reference: MoshoTopUp returns the existing purchase instead of charging again. A **new** reference is a **new** charge. Only create a new reference for a new purchase, such as after `TopUpFailed` or when the number or plan changes.

## Test numbers

The fake backend decides the outcome from the last digit of the phone number:

| Number ends in | Result |
| --- | --- |
| `0` | `TopUpPending`, then `TopUpSuccess` after two `status()` checks |
| `9` | `TopUpFailed`, with no charge |
| anything else | `TopUpSuccess` |

Every charge is printed to the console, and the backend prints a warning when the same number is charged more than once for the same plan, which usually means a retry used a new reference.

## API

| Member | Description |
| --- | --- |
| `MoshoTopUp({required String apiKey, Duration latency})` | Creates a client. Create one and reuse it. |
| `plans({required Network network})` | Current plans for a network. |
| `buyData({required String phone, required String planId, required String reference})` | Buys a plan. |
| `status(String reference)` | Current state of a purchase. |
| `normalizeNigerianPhone(String input)` | Converts user input to `+234` format. |
| `formatNaira(int kobo)` | Formats kobo as a naira label, like `₦1,000`. |
| `newReference()` | Creates a unique purchase reference. |
