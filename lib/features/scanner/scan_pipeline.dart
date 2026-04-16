import 'dart:async';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'foil_detector.dart';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';

enum CaptureOutcome { matched, noMatch, offline }

class CaptureResult {
  CaptureResult.matched({
    required this.collectionId,
    required this.card,
    required this.price,
    required this.foil,
    required this.wasInsertion,
  })  : outcome = CaptureOutcome.matched,
        debugOcrName = null,
        debugOcrSet = null,
        debugBlocks = null;

  CaptureResult.noMatch({this.debugOcrName, this.debugOcrSet, this.debugBlocks})
      : outcome = CaptureOutcome.noMatch,
        collectionId = null,
        card = null,
        price = null,
        foil = false,
        wasInsertion = false;

  CaptureResult.offline()
      : outcome = CaptureOutcome.offline,
        collectionId = null,
        card = null,
        price = null,
        foil = false,
        wasInsertion = false,
        debugOcrName = null,
        debugOcrSet = null,
        debugBlocks = null;

  final CaptureOutcome outcome;
  final int? collectionId;
  final ScryfallCard? card;
  final double? price;
  final bool foil;
  final bool wasInsertion;
  final String? debugOcrName;
  final String? debugOcrSet;
  final String? debugBlocks;
}

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.matcher,
    required this.collection,
    this.matchTimeout = const Duration(seconds: 4),
  });

  final OcrRunner ocr;
  final ScanMatcher matcher;
  final CollectionRepository collection;
  final Duration matchTimeout;

  // Vertical bands where we expect each field. Anything lands in `_nameBand`
  // could be the card name; the winner is the widest block there. Blocks in
  // `_setBand` are concatenated for collector-number / set-code parsing.
  // These are intentionally wider than the old fixed crops — borderless,
  // showcase, and retro frames don't line up with a single fixed rectangle.
  // Widened from 0.30/0.78 — retro frames push the name banner lower (thick
  // top border) and the collector line higher; borderless cards vary too.
  static const double _nameBandBottom = 0.20;
  static const double _setBandTop = 0.70;
  static const double _setBandLeftMax = 0.75;

  Future<CaptureResult> captureFromWarpedCrop(
    Uint8List uprightPng, {
    bool forceFoil = false,
  }) async {
    var blocks = await ocr.recognizeBlocks(uprightPng);
    var rawName = _pickName(blocks);
    var rawSet = _pickSetCollector(blocks);

    // Orientation fix: if the picked name looks like rules/oracle text
    // (contains MTG gameplay keywords) OR both name and set are empty while
    // blocks DO exist (text is there, just not in the expected bands), the
    // card was likely warped upside down. Rotate 180° and re-OCR.
    final needsFlip = _looksLikeOracleText(rawName) ||
        (rawName.isEmpty && rawSet.isEmpty && blocks.isNotEmpty);
    if (needsFlip) {
      final decoded = img.decodeImage(uprightPng);
      if (decoded != null) {
        final rotated = img.copyRotate(decoded, angle: 180);
        uprightPng = Uint8List.fromList(img.encodePng(rotated));
        blocks = await ocr.recognizeBlocks(uprightPng);
        rawName = _pickName(blocks);
        rawSet = _pickSetCollector(blocks);
      }
    }
    final parsed = ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);
    final listCard = _detectListIcon(uprightPng);

    final ScryfallCard? card;
    try {
      card = await matcher
          .match(parsed, isListCard: listCard)
          .timeout(matchTimeout);
    } on TimeoutException {
      return CaptureResult.offline();
    } on ScryfallException {
      return CaptureResult.offline();
    }

    if (card == null) {
      final debugBlockDump = blocks
          .map((b) =>
              'y:${b.top.toStringAsFixed(2)} x:${b.left.toStringAsFixed(2)} '
              'w:${b.width.toStringAsFixed(2)} "${b.text.replaceAll('\n', ' ').substring(0, b.text.length.clamp(0, 30))}"')
          .join('\n');
      return CaptureResult.noMatch(
          debugOcrName: rawName,
          debugOcrSet: rawSet,
          debugBlocks: debugBlockDump);
    }

    var foil = forceFoil;
    if (!foil) {
      try {
        final sig = detectFoil(uprightPng);
        foil = sig.isFoil;
      } catch (_) {
        foil = false;
      }
    }

    final result = await collection.addFromScryfall(card, foil: foil);
    final price = _selectPrice(card, foil);
    return CaptureResult.matched(
      collectionId: result.id,
      card: card,
      price: price,
      foil: foil,
      wasInsertion: result.wasInsertion,
    );
  }

  // MTG gameplay keywords that appear in oracle/rules text but never in card
  // names. If the "name" we picked contains one of these, the warp is almost
  // certainly upside down (rules text at the top instead of the name banner).
  /// Check the set-symbol area (bottom-left of the warped card) for the
  /// Planeswalker logo that indicates a "The List" card. The logo is a
  /// solid filled icon — distinctly denser than typical set symbols which
  /// are mostly outlines. We threshold the region and check the ratio of
  /// dark pixels: > 30% suggests a filled symbol like the Planeswalker face.
  static bool _detectListIcon(Uint8List uprightPng) {
    final cv.Mat src;
    try {
      src = cv.imdecode(uprightPng, cv.IMREAD_GRAYSCALE);
    } catch (_) {
      return false;
    }
    try {
      if (src.isEmpty) return false;
      final h = src.rows;
      final w = src.cols;
      // The set symbol sits at roughly (3-10%, 89-96%) of the card.
      final x = (w * 0.03).round();
      final y = (h * 0.89).round();
      final rw = (w * 0.07).round();
      final rh = (h * 0.07).round();
      if (x + rw > w || y + rh > h) return false;
      final roi = src.region(cv.Rect(x, y, rw, rh));
      // OTSU threshold to separate symbol from background.
      final binary = cv.threshold(roi, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU).$2;
      try {
        final dark = cv.countNonZero(binary);
        final total = rw * rh;
        final ratio = total == 0 ? 0.0 : dark / total;
        return ratio > 0.30;
      } finally {
        roi.dispose();
        binary.dispose();
      }
    } finally {
      src.dispose();
    }
  }

  static final _oracleKeywords = RegExp(
      r'\b(mana|creature|target|counter|damage|draw|discard|exile|sacrifice|'
      r'graveyard|battlefield|enchant|equip|activate|upkeep|haste|flying|'
      r'trample|lifelink|vigilance|deathtouch|reach|menace|ward|hexproof|'
      r'indestructible|flash|defender)\b',
      caseSensitive: false);

  static bool _looksLikeOracleText(String name) {
    if (name.isEmpty) return false;
    return _oracleKeywords.hasMatch(name);
  }

  static final _hasLetter = RegExp(r'[A-Za-z]');

  static String _pickName(List<OcrBlock> blocks) {
    final candidates = blocks
        .where((b) =>
            b.top < _nameBandBottom &&
            _hasLetter.hasMatch(b.text) &&
            b.text.trim().length >= 3)
        .toList()
      ..sort((a, b) => b.width.compareTo(a.width));
    if (candidates.isEmpty) return '';
    final lines = candidates.first.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '';
    final first = lines.first;
    // Only the first line's mana cost / type line spillover on compact
    // frames poisons the fuzzy-name lookup, so we default to it. But when
    // the first line ends in a comma (e.g. "Urza,") or is a single bare
    // word ("Jace"), the real card name almost always continues onto the
    // second line — join it so names like "Urza, Lord Protector" survive.
    if (lines.length > 1 &&
        (first.endsWith(',') || !first.contains(' '))) {
      return '$first ${lines[1]}';
    }
    return first;
  }

  static String _pickSetCollector(List<OcrBlock> blocks) {
    final band = blocks
        .where((b) => b.top >= _setBandTop && b.left < _setBandLeftMax)
        .toList()
      ..sort((a, b) => a.left.compareTo(b.left));
    return band.map((b) => b.text.replaceAll('\n', ' ')).join(' ');
  }

  static double? _selectPrice(ScryfallCard card, bool foil) {
    final usd = card.prices.usd;
    final usdFoil = card.prices.usdFoil;
    if (foil) return usdFoil ?? usd;
    return usd ?? usdFoil;
  }
}

