import 'package:mosho_topup/mosho_topup.dart';
import 'package:mosho_topup/src/fake_backend.dart';
import 'package:test/test.dart';

void main() {
  late MoshoTopUp topup;

  setUp(() {
    FakeBackend.instance.reset();
    topup = MoshoTopUp(apiKey: 'test_mosho_123', latency: Duration.zero);
  });

  Future<DataPlan> mtn1GB() async =>
      (await topup.plans(network: Network.mtn)).firstWhere((plan) => plan.name == '1GB');

  group('normalizeNigerianPhone', () {
    test('accepts local, international and spaced formats', () {
      expect(normalizeNigerianPhone('08031234567'), '+2348031234567');
      expect(normalizeNigerianPhone('2348031234567'), '+2348031234567');
      expect(normalizeNigerianPhone('+234 803 123 4567'), '+2348031234567');
      expect(normalizeNigerianPhone('0803-123-4567'), '+2348031234567');
    });

    test('rejects numbers that are not Nigerian mobiles', () {
      expect(() => normalizeNigerianPhone('12345'), throwsFormatException);
      expect(() => normalizeNigerianPhone('06031234567'), throwsFormatException);
      expect(() => normalizeNigerianPhone('080312345678'), throwsFormatException);
    });
  });

  test('formatNaira converts kobo to a naira label', () {
    expect(formatNaira(100000), '₦1,000');
    expect(formatNaira(150), '₦1.50');
    expect(formatNaira(123456789), '₦1,234,567.89');
    expect(formatNaira(0), '₦0');
  });

  test('newReference creates unique references', () {
    expect(newReference(), isNot(newReference()));
  });

  test('plans are returned per network', () async {
    final plans = await topup.plans(network: Network.mtn);
    expect(plans, isNotEmpty);
    expect(plans.every((plan) => plan.network == Network.mtn), isTrue);
  });

  test('buyData rejects phone numbers that are not normalized', () async {
    final plan = await mtn1GB();
    expect(
      () => topup.buyData(phone: '08031234567', planId: plan.id, reference: newReference()),
      throwsArgumentError,
    );
  });

  test('a regular number succeeds immediately', () async {
    final plan = await mtn1GB();
    final result = await topup.buyData(
      phone: '+2348031234567',
      planId: plan.id,
      reference: newReference(),
    );
    expect(result, isA<TopUpSuccess>());
  });

  test('a number ending in 0 is pending until status is checked twice', () async {
    final plan = await mtn1GB();
    final reference = newReference();

    expect(
      await topup.buyData(phone: '+2348031234560', planId: plan.id, reference: reference),
      isA<TopUpPending>(),
    );
    expect(await topup.status(reference), isA<TopUpPending>());
    expect(await topup.status(reference), isA<TopUpSuccess>());
  });

  test('a number ending in 9 fails without a debit', () async {
    final plan = await mtn1GB();
    final result = await topup.buyData(
      phone: '+2348031234569',
      planId: plan.id,
      reference: newReference(),
    );
    expect(result, isA<TopUpFailed>());
    expect(FakeBackend.instance.debitCount, 0);
  });

  test('reusing a reference does not debit twice', () async {
    final plan = await mtn1GB();
    final reference = newReference();

    await topup.buyData(phone: '+2348031234560', planId: plan.id, reference: reference);
    await topup.buyData(phone: '+2348031234560', planId: plan.id, reference: reference);

    expect(FakeBackend.instance.debitCount, 1);
  });

  test('a new reference for the same purchase debits again', () async {
    final plan = await mtn1GB();

    await topup.buyData(phone: '+2348031234560', planId: plan.id, reference: newReference());
    await topup.buyData(phone: '+2348031234560', planId: plan.id, reference: newReference());

    expect(FakeBackend.instance.debitCount, 2);
  });

  test('a reference cannot be reused for a different purchase', () async {
    final plan = await mtn1GB();
    final reference = newReference();

    await topup.buyData(phone: '+2348031234567', planId: plan.id, reference: reference);
    final result = await topup.buyData(
      phone: '+2348039999997',
      planId: plan.id,
      reference: reference,
    );

    expect(result, isA<TopUpFailed>());
  });

  test('an unknown plan id fails', () async {
    final result = await topup.buyData(
      phone: '+2348031234567',
      planId: 'mtn-1gb',
      reference: newReference(),
    );
    expect(result, isA<TopUpFailed>());
  });
}
