import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 7. Payments and wallet.

Future<Json> _wallet(AppState state) async =>
    unwrap(await state.api.get('/rider/wallet')) as Json;

const _txIcons = {
  'charge': Icons.receipt_long_rounded,
  'refund': Icons.undo_rounded,
  'wallet_topup': Icons.add_card_rounded,
  'wallet_payment': Icons.account_balance_wallet_rounded,
  'tip': Icons.volunteer_activism_rounded,
  'referral_credit': Icons.card_giftcard_rounded,
};

class _TxTile extends StatelessWidget {
  const _TxTile(this.tx);
  final Json tx;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final credit = tx.str('direction') == 'credit';
    final isTrip =
        tx.strOrNull('subject_type') == 'trip' && tx['subject_id'] != null;
    return MenuTile(
      icon: _txIcons[tx.str('type')] ?? Icons.payments_rounded,
      title: tx.strOrNull('description') ?? humanize(tx.str('type')),
      subtitle: [
        fmtDayTime(tx.date('created_at')),
        paymentLabels[tx.str('method')] ?? humanize(tx.str('method')),
        if (tx.str('status') != 'succeeded') humanize(tx.str('status')),
      ].join(' • '),
      onTap: !isTrip
          ? null
          : () => runAction(context, () async {
              final trip = await state.loadTrip(tx.integer('subject_id'));
              state.select(pastTrip: trip);
              if (context.mounted) go(context, '/receipt');
            }),
      trailing: Text(
        '${credit ? '+' : '−'} ${naira(tx.integer('amount'))}',
        style: CaboText.h3.copyWith(
          fontSize: 14,
          color: credit ? CaboColors.green : CaboColors.ink,
        ),
      ),
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json>(
      load: () => _wallet(state),
      builder: (context, w, reload) {
        final balance = w.integer('balance');
        final recent = w.list('recent');
        return CaboScaffold(
          title: 'Wallet',
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CaboColors.green, CaboColors.deepGreen],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cabo Wallet',
                    style: CaboText.label.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    naira(balance),
                    style: CaboText.display.copyWith(color: Colors.white),
                  ),
                  if (state.homePrice(balance).isNotEmpty)
                    Text(
                      state.homePrice(balance),
                      style: CaboText.body.copyWith(color: Colors.white70),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CaboButton(
                          'Top up',
                          style: CaboButtonStyle.accent,
                          icon: Icons.add_rounded,
                          height: 46,
                          onPressed: () async {
                            await Navigator.of(context).pushNamed('/top-up');
                            await reload();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CaboButton(
                          'History',
                          style: CaboButtonStyle.light,
                          height: 46,
                          onPressed: () => go(context, '/transactions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SectionTitle('Manage'),
            MenuTile(
              icon: Icons.credit_card_rounded,
              title: 'Ways to pay',
              subtitle: 'Card, wallet, bank transfer or cash',
              onTap: () => go(context, '/payment-methods'),
            ),
            MenuTile(
              icon: Icons.local_offer_rounded,
              title: 'Promo codes',
              subtitle: state.promoCode == null
                  ? 'Enter a code'
                  : '${state.promoCode} on your next ride',
              color: CaboColors.orange,
              onTap: () => go(context, '/promos'),
            ),
            MenuTile(
              icon: Icons.card_giftcard_rounded,
              title: 'Rewards and referrals',
              subtitle: '${compact(w.integer('loyalty_points'))} points',
              color: CaboColors.blue,
              onTap: () => go(context, '/rewards'),
            ),
            const SectionTitle('Recent'),
            if (recent.isEmpty) Text('No payments yet.', style: CaboText.muted),
            for (final tx in recent) _TxTile(tx),
          ],
        );
      },
    );
  }
}

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  static const _amounts = [5000, 10000, 20000, 50000];
  static const _methods = ['card', 'bank_transfer'];
  int _amount = 1;
  int _method = 0;

  Future<void> _topUp() async {
    final state = AppScope.read(context);
    final res = unwrap(
      await state.api.post('/rider/wallet/top-up', {
        'amount': _amounts[_amount],
        'method': _methods[_method],
      }),
    ) as Json;
    await state.refreshRider();
    if (!mounted) return;
    showMessage(
      context,
      'Wallet topped up. New balance ${naira(res.integer('balance'))}.',
    );
    back(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final value = _amounts[_amount];
    return CaboScaffold(
      title: 'Top up wallet',
      bottom: ActionButton('Top up ${naira(value)}', onPressed: _topUp),
      children: [
        Center(child: Text(naira(value), style: CaboText.display)),
        if (state.homePrice(value).isNotEmpty)
          Center(child: Text(state.homePrice(value), style: CaboText.muted)),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3,
          children: [
            for (var i = 0; i < _amounts.length; i++)
              GestureDetector(
                onTap: () => setState(() => _amount = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == _amount ? CaboColors.green : CaboColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    naira(_amounts[i]),
                    style: CaboText.h3.copyWith(
                      color: i == _amount ? Colors.white : CaboColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SectionTitle('Pay with'),
        SingleChoice(
          initial: _method,
          icons: const [
            Icons.credit_card_rounded,
            Icons.account_balance_rounded,
          ],
          options: const [
            ('Card', 'Visa, Mastercard or Verve'),
            ('Bank transfer', null),
          ],
          onChanged: (i) => _method = i,
        ),
      ],
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const methods = [
      (
        'card',
        Icons.credit_card_rounded,
        'Visa, Mastercard and Verve, from Nigeria and abroad',
      ),
      ('wallet', Icons.account_balance_wallet_rounded, null),
      (
        'bank_transfer',
        Icons.account_balance_rounded,
        'For rides, tours and shuttles',
      ),
      ('cash', Icons.payments_rounded, 'Rides only, paid to the driver'),
    ];
    return CaboScaffold(
      title: 'Ways to pay',
      children: [
        Text(
          'Choose how you pay for rides. You can change it for each booking.',
          style: CaboText.muted.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        for (final (code, icon, note) in methods)
          MenuTile(
            icon: icon,
            title: paymentLabels[code] ?? humanize(code),
            subtitle: code == 'wallet'
                ? 'Balance ${naira(state.rider?.integer('wallet_balance') ?? 0)}'
                : note,
            trailing: state.paymentMethod == code
                ? const Pill('Default')
                : const Icon(
                    Icons.circle_outlined,
                    color: CaboColors.muted,
                    size: 20,
                  ),
            onTap: () => state.choosePayment(code),
          ),
        const SizedBox(height: 12),
        CaboCard(
          color: CaboColors.surface,
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, size: 18, color: CaboColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saving a card for one-tap payment is coming soon.',
                  style: CaboText.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StateScreen(
      icon: Icons.credit_card_rounded,
      title: 'Saved cards are coming soon',
      message:
          'For now, choose card, wallet, bank transfer or cash each time you book. '
          'Cabo never stores your card number in this app.',
      primary: 'Ways to pay',
      onPrimary: () => replace(context, '/payment-methods'),
      top: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => back(context),
      ),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _filters = [
    ('All', null),
    ('Payments', 'charge'),
    ('Top-ups', 'wallet_topup'),
    ('Refunds', 'refund'),
    ('Tips', 'tip'),
  ];
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final type = _filters[_filter].$2;
    return CaboScaffold(
      title: 'Transactions',
      children: [
        ChipPicker(
          options: [for (final f in _filters) f.$1],
          initial: {_filter},
          single: true,
          onChanged: (s) => setState(() => _filter = s.first),
        ),
        const SizedBox(height: 14),
        Loader<List<Json>>(
          key: ValueKey(type),
          load: () async => (await state.api.get(
            '/rider/wallet/transactions',
            query: {'type': ?type},
          ) as Json).list('data'),
          builder: (context, items, _) => items.isEmpty
              ? const EmptyNotice(
                  'Nothing here yet.',
                  icon: Icons.receipt_long_rounded,
                )
              : Column(children: [for (final tx in items) _TxTile(tx)]),
        ),
      ],
    );
  }
}

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Loader<Json?>(
      load: () async {
        if (state.pastTrip != null) return state.pastTrip;
        final done = (await state.api.get(
          '/rider/trips',
          query: {'status': 'completed'},
        ) as Json).list('data');
        return done.isEmpty ? null : done.first;
      },
      builder: (context, t, _) {
        if (t == null) {
          return CaboScaffold(
            title: 'Receipt',
            children: const [
              EmptyNotice(
                'Receipts for your completed rides appear here.',
                icon: Icons.receipt_long_rounded,
              ),
            ],
          );
        }
        final total = t.integer('fare_total') + t.integer('tip');
        final driver = t.obj('driver');
        final vehicle = t.obj('vehicle');
        String short(String a) => a.split(',').first;
        return CaboScaffold(
          title: 'Receipt',
          bottom: CaboButton(
            'Get help with this trip',
            style: CaboButtonStyle.secondary,
            onPressed: () {
              state.select(pastTrip: t);
              go(context, '/report-issue');
            },
          ),
          children: [
            const Center(child: CaboLogo(size: 40)),
            const SizedBox(height: 14),
            Center(child: Text(naira(total), style: CaboText.display)),
            Center(
              child: Text(
                [
                  '${humanize(t.str('payment_status'))} • ${paymentLabels[t.str('payment_method')] ?? ''}',
                  if (state.homePrice(total).isNotEmpty) state.homePrice(total),
                ].join(' • '),
                style: CaboText.muted,
              ),
            ),
            const SizedBox(height: 20),
            CaboCard(
              child: Column(
                children: [
                  InfoRow(
                    'Date',
                    fmtDayTime(t.date('completed_at') ?? t.date('created_at')),
                  ),
                  InfoRow(
                    'Route',
                    '${short(t.str('pickup_address'))} → ${short(t.str('dropoff_address'))}',
                  ),
                  if (driver != null)
                    InfoRow(
                      'Driver',
                      [
                        driver.str('first_name'),
                        ?vehicle?.strOrNull('plate_number'),
                      ].join(' • '),
                    ),
                  InfoRow(
                    'Distance',
                    '${t.number('distance_km').toStringAsFixed(1)} km',
                  ),
                  const Divider(height: 20),
                  InfoRow('Base fare', naira(t.integer('fare_base'))),
                  InfoRow('Distance', naira(t.integer('fare_distance'))),
                  InfoRow('Time', naira(t.integer('fare_time'))),
                  if (t.integer('fare_stops') > 0)
                    InfoRow('Stops', naira(t.integer('fare_stops'))),
                  if (t.integer('tolls') > 0)
                    InfoRow('Tolls', naira(t.integer('tolls'))),
                  if (t.integer('discount') > 0)
                    InfoRow(
                      'Discount',
                      '− ${naira(t.integer('discount'))}',
                      valueColor: CaboColors.green,
                    ),
                  if (t.integer('cancellation_fee') > 0)
                    InfoRow(
                      'Cancellation fee',
                      naira(t.integer('cancellation_fee')),
                    ),
                  if (t.integer('tip') > 0)
                    InfoRow('Tip', naira(t.integer('tip'))),
                  InfoRow('Total', naira(total), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CaboCard(
              color: CaboColors.surface,
              child: InfoRow('Receipt number', t.str('reference')),
            ),
          ],
        );
      },
    );
  }
}

class PromosScreen extends StatefulWidget {
  const PromosScreen({super.key});

  @override
  State<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<PromosScreen> {
  static const _services = ['ride', 'tour', 'shuttle'];
  final _code = TextEditingController();
  int _service = 0;
  String? _error;
  Json? _applied;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final state = AppScope.read(context);
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a promo code.');
      return;
    }
    try {
      final res = await state.api.post('/rider/promo-codes/validate', {
        'code': code,
        'service': _services[_service],
      }) as Json;
      if (_services[_service] == 'ride') state.promoCode = res.str('code');
      if (_services[_service] == 'tour') state.tourPromo = res.str('code');
      state.changed();
      if (mounted) {
        setState(() {
          _applied = res;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _applied = null;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final applied = _applied;
    return CaboScaffold(
      title: 'Promo codes',
      children: [
        Text('Use it on', style: CaboText.label),
        const SizedBox(height: 8),
        ChipPicker(
          options: const ['Rides', 'Tours', 'Airport shuttles'],
          initial: {_service},
          single: true,
          onChanged: (s) => _service = s.first,
        ),
        const SizedBox(height: 12),
        CaboField(
          'Enter a code',
          controller: _code,
          hint: 'e.g. LAGOS10',
          icon: Icons.local_offer_outlined,
          error: _error,
        ),
        ActionButton('Apply', onPressed: _apply),
        if (applied != null) ...[
          const SizedBox(height: 16),
          CaboCard(
            color: CaboColors.yellowSoft,
            child: Row(
              children: [
                const IconBadge(
                  Icons.local_offer_rounded,
                  color: CaboColors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applied.str('code'),
                        style: CaboText.label.copyWith(
                          color: CaboColors.orange,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        applied.strOrNull('description') ?? 'Code accepted',
                        style: CaboText.h3,
                      ),
                      Text(
                        _services[_service] == 'shuttle'
                            ? 'Enter this code when you book your shuttle.'
                            : 'Applied to your next ${_services[_service]} booking.',
                        style: CaboText.muted,
                      ),
                    ],
                  ),
                ),
                const Pill('Valid'),
              ],
            ),
          ),
        ],
        if (state.promoCode != null || state.tourPromo != null) ...[
          const SectionTitle('Ready to use'),
          if (state.promoCode != null)
            MenuTile(
              icon: Icons.local_taxi_rounded,
              title: state.promoCode!,
              subtitle: 'On your next ride',
              trailing: IconButton(
                tooltip: 'Remove code',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  state.promoCode = null;
                  state.changed();
                },
              ),
            ),
          if (state.tourPromo != null)
            MenuTile(
              icon: Icons.tour_rounded,
              title: state.tourPromo!,
              subtitle: 'On your next tour booking',
              trailing: IconButton(
                tooltip: 'Remove code',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  state.tourPromo = null;
                  state.changed();
                },
              ),
            ),
        ],
      ],
    );
  }
}
