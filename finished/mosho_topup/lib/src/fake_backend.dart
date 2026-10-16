import 'data_plan.dart';
import 'money.dart';
import 'network.dart';
import 'top_up_result.dart';

final class FakeBackend {
  FakeBackend._();

  static final FakeBackend instance = FakeBackend._();

  static const _statusChecksUntilDelivered = 2;

  static const _catalogue = <DataPlan>[
    DataPlan(id: 'pln_m1q7', network: Network.mtn, name: '500MB', amountInKobo: 50000, validityDays: 7),
    DataPlan(id: 'pln_m4x2', network: Network.mtn, name: '1GB', amountInKobo: 100000, validityDays: 30),
    DataPlan(id: 'pln_m9c5', network: Network.mtn, name: '2.5GB', amountInKobo: 200000, validityDays: 30),
    DataPlan(id: 'pln_m3h8', network: Network.mtn, name: '10GB', amountInKobo: 500000, validityDays: 30),
    DataPlan(id: 'pln_a2k9', network: Network.airtel, name: '1GB', amountInKobo: 100000, validityDays: 30),
    DataPlan(id: 'pln_a7d3', network: Network.airtel, name: '3GB', amountInKobo: 150000, validityDays: 30),
    DataPlan(id: 'pln_g5t1', network: Network.glo, name: '1.2GB', amountInKobo: 100000, validityDays: 30),
    DataPlan(id: 'pln_g8r6', network: Network.glo, name: '5GB', amountInKobo: 250000, validityDays: 30),
    DataPlan(id: 'pln_n6w4', network: Network.nineMobile, name: '1GB', amountInKobo: 100000, validityDays: 30),
  ];

  final _transactions = <String, _Transaction>{};
  final _debitsByPurchase = <String, int>{};

  int get debitCount => _debitsByPurchase.values.fold(0, (sum, count) => sum + count);

  void reset() {
    _transactions.clear();
    _debitsByPurchase.clear();
  }

  List<DataPlan> plansFor(Network network) =>
      List.unmodifiable(_catalogue.where((plan) => plan.network == network));

  TopUpResult buy({
    required String phone,
    required String planId,
    required String reference,
  }) {
    final existing = _transactions[reference];
    if (existing != null) {
      if (existing.phone != phone || existing.plan.id != planId) {
        return TopUpFailed(
          reference: reference,
          message: 'This reference was already used for a different purchase.',
        );
      }
      return existing.result;
    }

    final plan = _catalogue.where((plan) => plan.id == planId).firstOrNull;
    if (plan == null) {
      return TopUpFailed(
        reference: reference,
        message: 'Unknown plan "$planId". Load the current plans with plans().',
      );
    }

    final transaction = _Transaction(
      phone: phone,
      plan: plan,
      reference: reference,
      state: _initialState(phone),
    );
    _transactions[reference] = transaction;
    if (transaction.state != _State.failed) {
      _debit(transaction);
    }
    return transaction.result;
  }

  TopUpResult status(String reference) {
    final transaction = _transactions[reference];
    if (transaction == null) {
      return TopUpFailed(
        reference: reference,
        message: 'No purchase found for this reference.',
      );
    }
    if (transaction.state == _State.pending &&
        ++transaction.statusChecks >= _statusChecksUntilDelivered) {
      transaction.state = _State.success;
    }
    return transaction.result;
  }

  static _State _initialState(String phone) {
    if (phone.endsWith('9')) return _State.failed;
    if (phone.endsWith('0')) return _State.pending;
    return _State.success;
  }

  void _debit(_Transaction transaction) {
    final purchase = '${transaction.phone}|${transaction.plan.id}';
    final count = _debitsByPurchase.update(purchase, (count) => count + 1, ifAbsent: () => 1);
    print(
      '[mosho_topup] Debited ${formatNaira(transaction.plan.amountInKobo)} '
      'for ${transaction.plan.name} to ${transaction.phone} (ref ${transaction.reference})',
    );
    if (count > 1) {
      print(
        '[mosho_topup] WARNING: ${transaction.phone} has now been debited $count times '
        'for ${transaction.plan.name}. Did you retry with a new reference?',
      );
    }
  }
}

enum _State { pending, success, failed }

final class _Transaction {
  _Transaction({
    required this.phone,
    required this.plan,
    required this.reference,
    required this.state,
  });

  final String phone;
  final DataPlan plan;
  final String reference;
  _State state;
  int statusChecks = 0;

  TopUpResult get result => switch (state) {
        _State.pending => TopUpPending(reference: reference),
        _State.success => TopUpSuccess(reference: reference, phone: phone, plan: plan),
        _State.failed => TopUpFailed(
            reference: reference,
            message: '${plan.network.label} could not deliver this plan right now. You were not charged.',
          ),
      };
}
