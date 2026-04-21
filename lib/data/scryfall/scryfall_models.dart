class ScryfallPrices {
  ScryfallPrices({this.usd, this.usdFoil, this.eur, this.eurFoil});
  final double? usd;
  final double? usdFoil;
  final double? eur;
  final double? eurFoil;

  factory ScryfallPrices.fromJson(Map<String, dynamic> j) => ScryfallPrices(
        usd: _parseDouble(j['usd']),
        usdFoil: _parseDouble(j['usd_foil']),
        eur: _parseDouble(j['eur']),
        eurFoil: _parseDouble(j['eur_foil']),
      );

  static double? _parseDouble(Object? v) =>
      v is String ? double.tryParse(v) : (v is num ? v.toDouble() : null);
}

class ScryfallSet {
  ScryfallSet({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory ScryfallSet.fromJson(Map<String, dynamic> j) => ScryfallSet(
        code: j['code'] as String,
        name: j['name'] as String,
      );
}

class ScryfallCard {
  ScryfallCard({
    required this.id,
    required this.name,
    required this.set,
    required this.setName,
    required this.collectorNumber,
    required this.prices,
    this.imageUriSmall,
    this.imageUriNormal,
    this.rarity,
  });

  final String id;
  final String name;
  final String set;
  final String setName;
  final String collectorNumber;
  final ScryfallPrices prices;
  final String? imageUriSmall;
  final String? imageUriNormal;
  final String? rarity;

  factory ScryfallCard.fromJson(Map<String, dynamic> j) {
    final imgs = (j['image_uris'] as Map<String, dynamic>?) ??
        ((j['card_faces'] as List?)?.first as Map<String, dynamic>?)
            ?['image_uris'] as Map<String, dynamic>?;
    return ScryfallCard(
      id: j['id'] as String,
      name: j['name'] as String,
      set: j['set'] as String,
      setName: (j['set_name'] as String?) ?? (j['set'] as String),
      collectorNumber: j['collector_number'] as String,
      prices: ScryfallPrices.fromJson(
          (j['prices'] as Map?)?.cast<String, dynamic>() ?? const {}),
      imageUriSmall: imgs?['small'] as String?,
      imageUriNormal: imgs?['normal'] as String?,
      rarity: j['rarity'] as String?,
    );
  }
}

