import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/scanner/parsed_ocr.dart';

void main() {
  group('cleanName', () {
    test('collapses whitespace and trims', () {
      expect(ParsedOcr.cleanName('  Lightning   Bolt '), 'Lightning Bolt');
    });
    test('strips mana-symbol OCR noise like {R} or (R)', () {
      expect(ParsedOcr.cleanName('Lightning Bolt {R}'), 'Lightning Bolt');
      expect(ParsedOcr.cleanName('Lightning Bolt (R)'), 'Lightning Bolt');
    });
    test('preserves commas and apostrophes', () {
      expect(ParsedOcr.cleanName("Jace, the Mind Sculptor"),
          "Jace, the Mind Sculptor");
    });
    test('returns empty when input is only symbols', () {
      expect(ParsedOcr.cleanName('{R}{R}'), '');
    });
  });

  group('parseSetCollector', () {
    test('extracts set and number from "2xm 137"', () {
      final r = ParsedOcr.parseSetCollector('2xm 137');
      expect(r, isNotNull);
      expect(r!.set, '2XM');
      expect(r.collectorNumber, '137');
    });
    test('handles "137/274 M 2XM" (reversed order)', () {
      final r = ParsedOcr.parseSetCollector('137/274 M 2XM');
      expect(r, isNotNull);
      expect(r!.set, '2XM');
      expect(r.collectorNumber, '137');
    });
    test('keeps letter-suffixed numbers like 137a', () {
      final r = ParsedOcr.parseSetCollector('neo 137a');
      expect(r!.collectorNumber, '137a');
    });
    test('returns null on garbage', () {
      expect(ParsedOcr.parseSetCollector('zzzzzz'), isNull);
    });
  });

  test('ParsedOcr.from combines raw strings', () {
    final p = ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137');
    expect(p.name, 'Lightning Bolt');
    expect(p.setCode, '2XM');
    expect(p.collectorNumber, '137');
  });
}

