import 'dart:async';
import 'dart:typed_data';

import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'foil_detector.dart';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';
import 'thumbnail_storage.dart';

enum CaptureOutcome { matched, noMatch, offline }

class CaptureResult {
  CaptureResult.matched({
    required this.collectionId,
    required this.card,
    required this.price,
    required this.foil,
    required this.wasInsertion,
  }) : outcome = CaptureOutcome.matched;

  CaptureResult.noMatch()
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
        wasInsertion = false;

  final CaptureOutcome outcome;
  final int? collectionId;
  final ScryfallCard? card;
  final double? price;
  final bool foil;
  final bool wasInsertion;
}

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.storage,
    required this.matcher,
    required this.collection,
    this.matchTimeout = const Duration(seconds: 4),
  });

  final OcrRunner ocr;
  final ThumbnailStorage storage;
  final ScanMatcher matcher;
  final CollectionRepository collection;
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

    final ScryfallCard? card;
    try {
      card = await matcher.match(parsed).timeout(matchTimeout);
    } on TimeoutException {
      return CaptureResult.offline();
    } on ScryfallException {
      return CaptureResult.offline();
    }

    if (card == null) return CaptureResult.noMatch();

    var foil = forceFoil;
    if (!foil) {
      try {
        final sig = detectFoil(uprightPng);
        foil = sig.isFoil;
      } catch (_) {
        foil = false;
      }
    }

    await storage.save(uprightPng);
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

  static double? _selectPrice(ScryfallCard card, bool foil) {
    final usd = card.prices.usd;
    final usdFoil = card.prices.usdFoil;
    if (foil) return usdFoil ?? usd;
    return usd ?? usdFoil;
  }
}
