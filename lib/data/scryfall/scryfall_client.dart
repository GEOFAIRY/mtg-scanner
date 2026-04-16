import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'scryfall_models.dart';

class ScryfallException implements Exception {
  ScryfallException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ScryfallException($statusCode): $message';
}

class ScryfallNotFound extends ScryfallException {
  ScryfallNotFound(super.message) : super(statusCode: 404);
}

class ScryfallClient {
  ScryfallClient(this._http, {Duration minGap = const Duration(milliseconds: 100)})
      : _minGap = minGap;

  static const _base = 'https://api.scryfall.com';
  static const _headers = {
    'User-Agent': 'mtg-scanner/0.1',
    'Accept': 'application/json',
  };

  final http.Client _http;
  final Duration _minGap;
  Completer<void>? _tail;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Serialize requests with a minimum gap between them. Each call takes a
  /// ticket on a FIFO chain; the next caller waits for the prior ticket to
  /// complete before entering. Errors from [fn] propagate to the caller
  /// without breaking the chain — the ticket is always released in the
  /// finally so queued callers continue.
  Future<T> _throttled<T>(Future<T> Function() fn) async {
    final prev = _tail;
    final ticket = Completer<void>();
    _tail = ticket;
    try {
      if (prev != null) await prev.future;
      final wait = _minGap - DateTime.now().difference(_last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _last = DateTime.now();
      return await fn();
    } finally {
      if (identical(_tail, ticket)) _tail = null;
      ticket.complete();
    }
  }

  Future<ScryfallCard> cardBySetAndNumber(String set, String number) {
    return _throttled(() async {
      final uri = Uri.parse('$_base/cards/$set/$number');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) throw ScryfallNotFound('$set/$number');
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      return ScryfallCard.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
    });
  }

  Future<ScryfallCard> cardByFuzzyName(String name) {
    return _throttled(() async {
      final uri = Uri.parse('$_base/cards/named?fuzzy=${Uri.encodeQueryComponent(name)}');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) throw ScryfallNotFound(name);
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      return ScryfallCard.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
    });
  }

  Future<List<String>> autocomplete(String partial) {
    return _throttled(() async {
      final uri = Uri.parse(
          '$_base/cards/autocomplete?q=${Uri.encodeQueryComponent(partial)}');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      final data = (jsonDecode(r.body) as Map<String, dynamic>)['data'];
      return (data as List).cast<String>();
    });
  }

  /// Search for a card by exact name and collector number across all sets.
  ///
  /// Card names OCR much more reliably than the tiny set-code glyph; pairing a
  /// confident name with the collector number almost always resolves to a
  /// single printing (or a small set of reprints where the latest is the best
  /// default guess, hence `order=released`).
  Future<List<ScryfallCard>> cardsByNameAndCollectorNumber(
      String name, String collectorNumber) {
    return _throttled(() async {
      final q = Uri.encodeQueryComponent(
          '!"$name" cn:$collectorNumber');
      final uri = Uri.parse('$_base/cards/search?q=$q&order=released');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) return <ScryfallCard>[];
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      final data = (jsonDecode(r.body) as Map<String, dynamic>)['data'] as List?;
      if (data == null) return <ScryfallCard>[];
      return data
          .map((j) => ScryfallCard.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  /// Fetch all printings of a card. [maxPages] bounds pagination — callers
  /// on the scan-latency critical path should pass 1 to avoid the hundreds-
  /// of-printings walk that basic lands like Mountain trigger (each page is
  /// another throttled round-trip).
  Future<List<ScryfallCard>> printingsOfName(String name,
      {int maxPages = 50}) async {
    final q = Uri.encodeQueryComponent('!"$name" unique:prints');
    var uri = Uri.parse('$_base/cards/search?q=$q&order=released');
    final all = <ScryfallCard>[];
    var pagesFetched = 0;
    while (pagesFetched < maxPages) {
      final page = await _throttled(() async {
        final r = await _http.get(uri, headers: _headers);
        if (r.statusCode == 404) return null;
        if (r.statusCode >= 400) {
          throw ScryfallException(r.body, statusCode: r.statusCode);
        }
        return jsonDecode(r.body) as Map<String, dynamic>;
      });
      if (page == null) break;
      pagesFetched++;
      final data = page['data'] as List?;
      if (data != null) {
        all.addAll(data.map(
            (j) => ScryfallCard.fromJson(j as Map<String, dynamic>)));
      }
      if (page['has_more'] == true && page['next_page'] is String) {
        uri = Uri.parse(page['next_page'] as String);
      } else {
        break;
      }
    }
    return all;
  }

  Future<ScryfallSet> setByCode(String code) {
    return _throttled(() async {
      final uri = Uri.parse('$_base/sets/$code');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) throw ScryfallNotFound(code);
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      return ScryfallSet.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
    });
  }
}

