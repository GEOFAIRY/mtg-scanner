import 'dart:async';
import 'dart:typed_data';

import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'foil_detector.dart';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';
import 'scan_writer.dart';
import 'thumbnail_storage.dart';

enum CaptureOutcome { matched, noMatch, offline }

class CaptureResult {
  CaptureResult.matched({
    required this.id,
    required this.matchedName,
    required this.price,
  }) : outcome = CaptureOutcome.matched;

  CaptureResult.noMatch()
      : outcome = CaptureOutcome.noMatch,
        id = null,
        matchedName = null,
        price = null;

  CaptureResult.offline()
      : outcome = CaptureOutcome.offline,
        id = null,
        matchedName = null,
        price = null;

  final CaptureOutcome outcome;
  final int? id;
  final String? matchedName;
  final double? price;
}

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.writer,
    required this.storage,
    required this.matcher,
    required this.collection,
    this.autoConfirmThreshold = 0.8,
    this.matchTimeout = const Duration(seconds: 4),
  });

  final OcrRunner ocr;
  final ScanWriter writer;
  final ThumbnailStorage storage;
  final ScanMatcher matcher;
  final CollectionRepository collection;
  final double autoConfirmThreshold;
  final Duration matchTimeout;

  static const _nameRegion =
      OcrRegion(left: 0.02, top: 0.02, width: 0.96, height: 0.14);
  static const _setRegion =
      OcrRegion(left: 0.02, top: 0.86, width: 0.60, height: 0.12);

  Future<CaptureResult> captureFromWarpedCrop(
    Uint8List uprightPng, {
    bool forceFoil = false,
  }) async {
    final rawName = await ocr.recognizeRegion(uprightPng, _nameRegion);
    final rawSet = await ocr.recognizeRegion(uprightPng, _setRegion);
    final parsed = ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);

    final MatchResult? match;
    try {
      match = await matcher.match(parsed).timeout(matchTimeout);
    } on TimeoutException {
      return CaptureResult.offline();
    } on ScryfallException {
      return CaptureResult.offline();
    }

    if (match == null) return CaptureResult.noMatch();

    var foilGuess = 0;
    if (forceFoil) {
      foilGuess = 1;
    } else {
      try {
        final sig = detectFoil(uprightPng);
        foilGuess = sig.isFoil ? 1 : 0;
      } catch (_) {
        foilGuess = 0;
      }
    }

    final thumbPath = await storage.save(uprightPng);
    final id = await writer.insertMatched(
      parsed: parsed,
      thumbPath: thumbPath,
      foilGuess: foilGuess,
      match: match,
    );

    if (match.confidence >= autoConfirmThreshold) {
      await collection.addFromScryfall(match.card, foil: foilGuess == 1);
      await writer.markConfirmed(id);
    }

    final price = _selectPrice(match.card, forceFoil || foilGuess == 1);
    return CaptureResult.matched(
      id: id,
      matchedName: match.card.name,
      price: price,
    );
  }

  static double? _selectPrice(ScryfallCard card, bool foil) {
    final usd = card.prices.usd;
    final usdFoil = card.prices.usdFoil;
    if (foil) return usdFoil ?? usd;
    return usd ?? usdFoil;
  }
}
