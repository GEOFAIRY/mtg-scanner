import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_client.dart';

class _MockHttp extends Mock implements http.Client {}

void main() {
  late _MockHttp http_;
  late ScryfallClient client;

  setUp(() {
    http_ = _MockHttp();
    client = ScryfallClient(http_, minGap: Duration.zero);
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  test('cardBySetAndNumber returns parsed card', () async {
    final body = File('test/fixtures/scryfall/lightning_bolt_2xm_137.json')
        .readAsStringSync();
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final card = await client.cardBySetAndNumber('2xm', '137');
    expect(card.name, 'Lightning Bolt');
    expect(card.set, '2xm');
    expect(card.prices.usd, 1.80);
  });

  test('throws ScryfallNotFound on 404', () async {
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"status":404}', 404));
    expect(() => client.cardBySetAndNumber('xxx', '0'),
        throwsA(isA<ScryfallNotFound>()));
  });

  test('error in one call does not stall queued callers', () async {
    final callHistory = <String>[];
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((inv) async {
      final url = (inv.positionalArguments[0] as Uri).toString();
      callHistory.add(url);
      if (url.contains('boom')) {
        return http.Response('server fire', 500);
      }
      return http.Response(
          jsonEncode({
            'id': 'x', 'name': 'X', 'set': 'xxx', 'collector_number': '1',
            'prices': {'usd': null, 'usd_foil': null},
          }),
          200);
    });
    final c = ScryfallClient(http_, minGap: Duration.zero);

    // First call fails; second call (queued behind it) must still complete.
    final first = c.cardBySetAndNumber('boom', '1');
    final second = c.cardBySetAndNumber('ok', '2');
    await expectLater(first, throwsA(isA<ScryfallException>()));
    final card = await second;
    expect(card.name, 'X');
    expect(callHistory, hasLength(2));
  });

  test('rate-limits to minGap between requests', () async {
    final times = <DateTime>[];
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async {
      times.add(DateTime.now());
      return http.Response(
          jsonEncode({
            'id': 'x', 'name': 'X', 'set': 'xxx', 'collector_number': '1',
            'prices': {'usd': null, 'usd_foil': null},
          }),
          200);
    });
    final c = ScryfallClient(http_, minGap: const Duration(milliseconds: 100));
    await Future.wait([
      c.cardBySetAndNumber('xxx', '1'),
      c.cardBySetAndNumber('xxx', '1'),
    ]);
    expect(times, hasLength(2));
    expect(times[1].difference(times[0]).inMilliseconds, greaterThanOrEqualTo(95));
  });
}

