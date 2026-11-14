import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

// 7. Payments and wallet.

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                naira(12400),
                style: CaboText.display.copyWith(color: Colors.white),
              ),
              Text(
                gbp(12400),
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
                      onPressed: () => go(context, '/top-up'),
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
          title: 'Payment methods',
          subtitle: 'Visa •• 4242 and 1 more',
          onTap: () => go(context, '/payment-methods'),
        ),
        MenuTile(
          icon: Icons.local_offer_rounded,
          title: 'Promo codes',
          subtitle: '1 active',
          color: CaboColors.orange,
          onTap: () => go(context, '/promos'),
        ),
        MenuTile(
          icon: Icons.receipt_long_rounded,
          title: 'Receipts and invoices',
          subtitle: 'Download PDFs',
          color: CaboColors.blue,
          onTap: () => go(context, '/transactions'),
        ),
        const SectionTitle('Recent'),
        InfoRow('Ride • Eko Hotel → Nike Art Gallery', '− ${naira(4000)}'),
        InfoRow(
          'Top up • Visa •• 4242',
          '+ ${naira(10000)}',
          valueColor: CaboColors.green,
        ),
        InfoRow(
          'Referral credit • Kemi joined',
          '+ ${naira(2000)}',
          valueColor: CaboColors.green,
        ),
      ],
    );
  }
}

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  int amount = 1;

  @override
  Widget build(BuildContext context) {
    const amounts = [5000, 10000, 20000, 50000];
    return CaboScaffold(
      title: 'Top up wallet',
      bottom: CaboButton(
        'Top up ${naira(amounts[amount])}',
        onPressed: () => back(context),
      ),
      children: [
        Center(child: Text(naira(amounts[amount]), style: CaboText.display)),
        Center(child: Text(gbp(amounts[amount]), style: CaboText.muted)),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3,
          children: [
            for (var i = 0; i < amounts.length; i++)
              GestureDetector(
                onTap: () => setState(() => amount = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == amount ? CaboColors.green : CaboColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    naira(amounts[i]),
                    style: CaboText.h3.copyWith(
                      color: i == amount ? Colors.white : CaboColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SectionTitle('Pay with'),
        const SingleChoice(
          icons: [Icons.credit_card_rounded, Icons.account_balance_rounded],
          options: [
            ('Visa •• 4242', null),
            ('Bank transfer', 'Virtual account'),
          ],
        ),
      ],
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card(
      String brand,
      String number,
      String exp,
      Color color,
      bool primary,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(brand, style: CaboText.h3.copyWith(color: Colors.white)),
                const Spacer(),
                if (primary) const Pill('Default', color: Colors.white),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              number,
              style: CaboText.h2.copyWith(
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            Text(exp, style: CaboText.label.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
    return CaboScaffold(
      title: 'Payment methods',
      bottom: CaboButton(
        'Add a card',
        icon: Icons.add_rounded,
        onPressed: () => go(context, '/add-card'),
      ),
      children: [
        card(
          'VISA',
          '•••• •••• •••• 4242',
          'Expires 08/28 • issued in the UK',
          const Color(0xFF1A3C8F),
          true,
        ),
        card(
          'VERVE',
          '•••• •••• •••• 1180',
          'Expires 02/27 • GTBank',
          const Color(0xFF0F5B36),
          false,
        ),
        const SectionTitle('Other ways to pay'),
        const MenuTile(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Cabo Wallet',
          subtitle: 'Balance ₦12,400',
        ),
        const MenuTile(
          icon: Icons.account_balance_rounded,
          title: 'Bank transfer',
          subtitle: 'For tours and shuttles',
        ),
        const MenuTile(
          icon: Icons.payments_rounded,
          title: 'Cash',
          subtitle: 'Rides only',
        ),
      ],
    );
  }
}

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Add a card',
      bottom: CaboButton('Save card', onPressed: () => back(context)),
      children: [
        const CaboField(
          'Card number',
          value: '5399 8312 •••• ••••',
          icon: Icons.credit_card_rounded,
        ),
        const Row(
          children: [
            Expanded(child: CaboField('Expiry', value: '11 / 29')),
            SizedBox(width: 12),
            Expanded(child: CaboField('CVV', hint: '123')),
          ],
        ),
        const CaboField('Name on card', value: 'TUNDE BAKARE'),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.lock_rounded, size: 18, color: CaboColors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'We accept Visa, Mastercard and Verve cards from Nigeria and abroad. '
                'A small refundable check may appear on your statement.',
                style: CaboText.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tx = [
      (
        'Today',
        'Ride • Eko Hotel → Nike Art Gallery',
        4000,
        Icons.local_taxi_rounded,
      ),
      ('Today', 'Tour • Lekki Conservation Centre', 33200, Icons.tour_rounded),
      (
        'Wed 14 Oct',
        'Airport pickup • MMIA → Ikoyi',
        25000,
        Icons.flight_land_rounded,
      ),
      (
        'Mon 12 Oct',
        'Ride • Ikoyi → Terra Kulture',
        2900,
        Icons.local_taxi_rounded,
      ),
      (
        'Sun 11 Oct',
        'Tour • Lagos Island Heritage Walk',
        18000,
        Icons.tour_rounded,
      ),
    ];
    return CaboScaffold(
      title: 'Transactions',
      children: [
        const ChipPicker(
          options: ['All', 'Rides', 'Tours', 'Shuttles', 'Wallet'],
          initial: {0},
          single: true,
        ),
        const SizedBox(height: 14),
        for (final (date, title, amount, icon) in tx)
          MenuTile(
            icon: icon,
            title: title,
            subtitle: '$date • ${gbp(amount)}',
            onTap: () => go(context, '/receipt'),
            trailing: Text(
              '− ${naira(amount)}',
              style: CaboText.h3.copyWith(fontSize: 14),
            ),
          ),
      ],
    );
  }
}

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Receipt',
      bottom: Row(
        children: [
          Expanded(
            child: CaboButton(
              'Email',
              style: CaboButtonStyle.secondary,
              icon: Icons.mail_outline,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CaboButton(
              'Download',
              icon: Icons.download_rounded,
              onPressed: () {},
            ),
          ),
        ],
      ),
      children: [
        const Center(child: CaboLogo(size: 40)),
        const SizedBox(height: 14),
        Center(child: Text(naira(4000), style: CaboText.display)),
        Center(
          child: Text(
            'Paid with Visa •• 4242 • ${gbp(4000)}',
            style: CaboText.muted,
          ),
        ),
        const SizedBox(height: 20),
        CaboCard(
          child: Column(
            children: [
              const InfoRow('Date', 'Fri 16 Oct 2026, 09:08'),
              const InfoRow('Route', 'Eko Hotel → Nike Art Gallery'),
              const InfoRow('Driver', 'Emeka N. • LND 482 KJ'),
              const Divider(height: 20),
              InfoRow('Trip fare', naira(3500)),
              InfoRow('Tip', naira(500)),
              InfoRow('Total', naira(4000), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const CaboField(
          'Company name on invoice',
          value: 'Bakare Consulting Ltd',
          icon: Icons.business_rounded,
        ),
        const CaboField('Receipt number', value: 'CB-7Q4-2291'),
      ],
    );
  }
}

class PromosScreen extends StatelessWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CaboScaffold(
      title: 'Promo codes',
      children: [
        Row(
          children: [
            const Expanded(
              child: CaboField('Enter a code', hint: 'e.g. LAGOS10'),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CaboButton(
                'Apply',
                height: 54,
                expand: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SectionTitle('Your offers'),
        for (final (code, title, sub, active) in const [
          (
            'WELCOME20',
            '20% off your first tour',
            'Up to ₦10,000 • ends Sun 25 Oct',
            true,
          ),
          (
            'AIRPORT5',
            '₦5,000 off an airport pickup',
            'Shuttles only • ends 31 Dec',
            true,
          ),
          ('KEMI2000', 'Referral credit added', '₦2,000 in your wallet', false),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaboCard(
              color: active ? CaboColors.yellowSoft : CaboColors.surface,
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
                          code,
                          style: CaboText.label.copyWith(
                            color: CaboColors.orange,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(title, style: CaboText.h3),
                        Text(sub, style: CaboText.muted),
                      ],
                    ),
                  ),
                  Pill(
                    active ? 'Active' : 'Used',
                    color: active ? CaboColors.green : CaboColors.muted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
