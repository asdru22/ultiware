enum ClothingSize { xs, s, m, l, xl, xxl }

enum ClothingBrand {
  a('Brand A'),
  b('Brand B'),
  c('Brand C'),
  d('Brand D');

  final String displayName;
  const ClothingBrand(this.displayName);
}

enum ClothingType {
  jersey('Jersey'),
  shorts('Shorts'),
  tank('Tank Top');

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