import '../app_settings.dart';
import '../data/db/database.dart';
import '../data/scryfall/scryfall_models.dart';

double? priceForRow(CollectionData r, PriceRegion region) {
  final foil = r.foil == 1;
  return switch (region) {
    PriceRegion.usd => foil ? (r.priceUsdFoil ?? r.priceUsd) : r.priceUsd,
    PriceRegion.eur => foil ? (r.priceEurFoil ?? r.priceEur) : r.priceEur,
  };
}

double? priceForCard(ScryfallCard c, bool foil, PriceRegion region) {
  final p = c.prices;
  return switch (region) {
    PriceRegion.usd =>
      foil ? (p.usdFoil ?? p.usd) : (p.usd ?? p.usdFoil),
    PriceRegion.eur =>
      foil ? (p.eurFoil ?? p.eur) : (p.eur ?? p.eurFoil),
  };
}
