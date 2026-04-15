import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/result_banner.dart';

ScryfallCard _card({String? rarity = 'uncommon'}) => ScryfallCard(
      id: 'sid-1',
      name: 'Lightning Bolt',
      set: '2xm',
      collectorNumber: '137',
      rarity: rarity,
      prices: ScryfallPrices(usd: 1.80),
    );

void main() {
  Widget _host(ResultBanner b) => MaterialApp(home: Scaffold(body: b));

  testWidgets('renders name, subtitle, and price', (tester) async {
    await tester.pumpWidget(_host(ResultBanner(
      data: BannerData(
          collectionId: 1,
          card: _card(),
          price: 1.80,
          foil: false,
          wasInsertion: true),
      onDismiss: () {},
      onEdit: () {},
    )));
    expect(find.text('Lightning Bolt'), findsOneWidget);
    expect(find.textContaining('2XM'), findsOneWidget);
    expect(find.textContaining('137'), findsOneWidget);
    expect(find.textContaining('uncommon'), findsOneWidget);
    expect(find.textContaining(r'$1.80'), findsOneWidget);
  });

  testWidgets('omits rarity segment when null', (tester) async {
    await tester.pumpWidget(_host(ResultBanner(
      data: BannerData(
          collectionId: 1,
          card: _card(rarity: null),
          price: 1.80,
          foil: false,
          wasInsertion: true),
      onDismiss: () {},
      onEdit: () {},
    )));
    expect(find.textContaining('uncommon'), findsNothing);
  });

  testWidgets('shows SizedBox.shrink when data is null', (tester) async {
    await tester.pumpWidget(
        _host(ResultBanner(data: null, onDismiss: () {}, onEdit: () {})));
    expect(find.text('Lightning Bolt'), findsNothing);
  });

  testWidgets('edit icon triggers onEdit', (tester) async {
    var edits = 0;
    await tester.pumpWidget(_host(ResultBanner(
      data: BannerData(
          collectionId: 1,
          card: _card(),
          price: 1.80,
          foil: false,
          wasInsertion: true),
      onDismiss: () {},
      onEdit: () => edits++,
    )));
    await tester.tap(find.byIcon(Icons.edit));
    expect(edits, greaterThanOrEqualTo(1));
  });

  testWidgets('close icon triggers onDismiss', (tester) async {
    var dismisses = 0;
    await tester.pumpWidget(_host(ResultBanner(
      data: BannerData(
          collectionId: 1,
          card: _card(),
          price: 1.80,
          foil: false,
          wasInsertion: true),
      onDismiss: () => dismisses++,
      onEdit: () {},
    )));
    await tester.tap(find.byIcon(Icons.close));
    expect(dismisses, 1);
  });
}
