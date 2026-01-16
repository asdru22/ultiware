enum ClothingSize { xs, s, m, l, xl, xxl }

enum ClothingBrand {
  vc('VC'),
  be('BE Ultimate'),
  boon('Boon'),
  dh('Double Happiness'),
  five('Five Ultimate'),
  trio('Trio'),
  paladin('Paladin'),
  force('Force Ultimate'),
  gaia('Gaia Ultimate');

  final String displayName;

  const ClothingBrand(this.displayName);
}

enum ClothingType {
  jersey('Jersey'),
  shorts('Shorts'),
  tank('Tank Top'),
  shortyShorts('Shorty Shorts'),
  hoodie('Hoodie'),
  sweater('Sweater'),
  jacket('Jacket'),
  longSleeve('Long Sleeve'),
  pants('Pants'),
  neckie('Neckie'),
  socks('Socks'),
  gloves('Gloves');

  final String displayName;

  const ClothingType(this.displayName);
}

class ClothingItem {
  final String id;
  final String frontImage;
  final String? backImage;
  final String? name;
  final ClothingSize? size;
  final ClothingBrand? brand;
  final ClothingType? type;
  final String? countryOfOrigin;
  final int? productionYear;
  final bool isFavorite;

  ClothingItem({
    required this.id,
    required this.frontImage,
    this.backImage,
    this.name,
    this.size,
    this.brand,
    this.type,
    this.countryOfOrigin,
    this.productionYear,
    this.isFavorite = false,
  });
}
