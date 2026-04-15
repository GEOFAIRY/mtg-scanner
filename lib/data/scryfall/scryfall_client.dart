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
  Future<void> _chain = Future.value();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  Future<T> _throttled<T>(Future<T> Function() fn) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      final now = DateTime.now();
      final wait = _minGap - now.difference(_last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _last = DateTime.now();
      try {
        completer.complete(await fn());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
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

  Future<List<ScryfallCard>> printingsOfName(String name) async {
    final q = Uri.encodeQueryComponent('!"$name" unique:prints');
    var uri = Uri.parse('$_base/cards/search?q=$q&order=released');
    final all = <ScryfallCard>[];
    while (true) {
      final page = await _throttled(() async {
        final r = await _http.get(uri, headers: _headers);
        if (r.statusCode == 404) return null;
        if (r.statusCode >= 400) {
          throw ScryfallException(r.body, statusCode: r.statusCode);
        }
        return jsonDecode(r.body) as Map<String, dynamic>;
      });
      if (page == null) break;
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

