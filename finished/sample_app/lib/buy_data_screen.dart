import 'package:flutter/material.dart';
import 'package:mosho_topup/mosho_topup.dart';

class BuyDataScreen extends StatefulWidget {
  const BuyDataScreen({super.key, this.client});

  final MoshoTopUp? client;

  @override
  State<BuyDataScreen> createState() => _BuyDataScreenState();
}

class _BuyDataScreenState extends State<BuyDataScreen> {
  static const _network = Network.mtn;
  static const _maxStatusChecks = 10;
  static const _statusInterval = Duration(seconds: 3);

  late final MoshoTopUp _topup = widget.client ?? MoshoTopUp(apiKey: 'test_mosho_123');
  late Future<List<DataPlan>> _plans = _topup.plans(network: _network);
  final _phoneController = TextEditingController();

  DataPlan? _selectedPlan;
  String? _phoneError;
  String? _reference;
  TopUpResult? _result;
  String? _connectionError;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _reloadPlans() {
    setState(() => _plans = _topup.plans(network: _network));
  }

  void _startNewPurchase() {
    _reference = null;
    _result = null;
    _connectionError = null;
  }

  String? _normalizedPhone() {
    try {
      return normalizeNigerianPhone(_phoneController.text);
    } on FormatException {
      return null;
    }
  }

  Future<void> _buy() async {
    final plan = _selectedPlan;
    if (plan == null || _busy) return;

    final phone = _normalizedPhone();
    if (phone == null) {
      setState(() => _phoneError = 'Enter a valid Nigerian number, like 0803 123 4567');
      return;
    }

    final reference = _reference ??= newReference();
    setState(() {
      _busy = true;
      _phoneError = null;
      _connectionError = null;
    });

    try {
      var result = await _topup.buyData(
        phone: phone,
        planId: plan.id,
        reference: reference,
      );

      for (var check = 0; result is TopUpPending && check < _maxStatusChecks; check++) {
        if (!mounted) return;
        setState(() => _result = result);
        await Future<void>.delayed(_statusInterval);
        result = await _topup.status(reference);
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        if (result is! TopUpPending) _reference = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectionError =
            'We could not reach MoshoTopUp. Tap "Try again" to retry the same purchase. You will not be charged twice.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _buttonLabel {
    final plan = _selectedPlan;
    if (_connectionError != null) return 'Try again';
    if (_result is TopUpPending) return 'Check again';
    if (plan == null) return 'Choose a plan';
    return 'Buy ${plan.name} for ${formatNaira(plan.amountInKobo)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Buy data', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '${_network.label} plans for any Nigerian number.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '0803 123 4567',
                errorText: _phoneError,
              ),
              onChanged: (_) => setState(() {
                _phoneError = null;
                _startNewPurchase();
              }),
            ),
            const SizedBox(height: 24),
            Text('Choose a plan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FutureBuilder<List<DataPlan>>(
              future: _plans,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _PlansError(onRetry: _reloadPlans);

                final plans = snapshot.data;
                if (plans == null) return const _PlansLoading();
                if (plans.isEmpty) {
                  return Text('No ${_network.label} plans are available right now.');
                }

                return Column(
                  children: [
                    for (final plan in plans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PlanOption(
                          plan: plan,
                          selected: plan.id == _selectedPlan?.id,
                          onTap: _busy
                              ? null
                              : () => setState(() {
                                    _selectedPlan = plan;
                                    _startNewPurchase();
                                  }),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_result != null || _connectionError != null) ...[
              _ResultPanel(result: _result, connectionError: _connectionError),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _selectedPlan == null || _busy ? null : _buy,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final DataPlan plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final validity = plan.validityDays == 1 ? 'Valid for 1 day' : 'Valid for ${plan.validityDays} days';

    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: theme.textTheme.titleMedium),
                      Text(
                        validity,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatNaira(plan.amountInKobo),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlansLoading extends StatelessWidget {
  const _PlansLoading();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Semantics(
      label: 'Loading plans',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlansError extends StatelessWidget {
  const _PlansError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('We could not load plans. Check your connection.')),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({this.result, this.connectionError});

  final TopUpResult? result;
  final String? connectionError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final error = connectionError;

    final content = error != null
        ? ('Connection problem', error, colors.errorContainer, colors.onErrorContainer)
        : switch (result) {
            TopUpSuccess(:final plan, :final phone) => (
                'Data delivered',
                '${plan.name} was sent to $phone.',
                colors.primaryContainer,
                colors.onPrimaryContainer,
              ),
            TopUpPending() => (
                'Processing',
                'The network is confirming your purchase. We will keep checking.',
                colors.secondaryContainer,
                colors.onSecondaryContainer,
              ),
            TopUpFailed(:final message) => (
                'Top-up failed',
                message,
                colors.errorContainer,
                colors.onErrorContainer,
              ),
            null => null,
          };

    if (content == null) return const SizedBox.shrink();
    final (title, body, background, foreground) = content;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(color: foreground)),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}
