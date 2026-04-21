import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/app_settings.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_card_scanner/features/scanner/result_banner.dart';

ScryfallCard _card({String? rarity = 'uncommon'}) => ScryfallCard(
      id: 'sid-1',
      name: 'Lightning Bolt',
      set: '2xm',
      setName: 'Double Masters',
      collectorNumber: '137',
      rarity: rarity,
      prices: ScryfallPrices(usd: 1.80),
    );

BannerData _banner({ScryfallCard? card, PriceRegion region = PriceRegion.usd}) =>
    BannerData(
      collectionId: 1,
      card: card ?? _card(),
      price: 1.80,
      region: region,
      foil: false,
      wasInsertion: true,
    );

void main() {
  Widget host(ResultBanner b) => MaterialApp(home: Scaffold(body: b));

  testWidgets('renders name, subtitle, and USD price', (tester) async {
    await tester.pumpWidget(host(ResultBanner(
      data: _banner(),
      onDismiss: () {},
      onEdit: () {},
    )));
    expect(find.text('Lightning Bolt'), findsOneWidget);
    expect(find.textContaining('2XM'), findsOneWidget);
    expect(find.textContaining('137'), findsOneWidget);
    expect(find.textContaining('uncommon'), findsOneWidget);
    expect(find.textContaining(r'$1.80'), findsOneWidget);
  });

  testWidgets('renders EUR symbol when region is eur', (tester) async {
    await tester.pumpWidget(host(ResultBanner(
      data: _banner(region: PriceRegion.eur),
      onDismiss: () {},
      onEdit: () {},
    )));
    expect(find.textContaining('€1.80'), findsOneWidget);
  });

  testWidgets('omits rarity segment when null', (tester) async {
    await tester.pumpWidget(host(ResultBanner(
      data: _banner(card: _card(rarity: null)),
      onDismiss: () {},
      onEdit: () {},
    )));
    expect(find.textContaining('uncommon'), findsNothing);
  });

  testWidgets('shows SizedBox.shrink when data is null', (tester) async {
    await tester.pumpWidget(
        host(ResultBanner(data: null, onDismiss: () {}, onEdit: () {})));
    expect(find.text('Lightning Bolt'), findsNothing);
  });

  testWidgets('edit icon triggers onEdit', (tester) async {
    var edits = 0;
    await tester.pumpWidget(host(ResultBanner(
      data: _banner(),
      onDismiss: () {},
      onEdit: () => edits++,
    )));
    await tester.tap(find.byIcon(Icons.edit));
    expect(edits, greaterThanOrEqualTo(1));
  });

  testWidgets('delete icon triggers onDismiss', (tester) async {
    var dismisses = 0;
    await tester.pumpWidget(host(ResultBanner(
      data: _banner(),
      onDismiss: () => dismisses++,
      onEdit: () {},
    )));
    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(dismisses, 1);
  });
}

