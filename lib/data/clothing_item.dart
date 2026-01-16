import 'package:flutter/material.dart';

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

enum ClothingSource {
  club('Club Team'),
  national('National Team'),
  college('College Team'),
  event('Event'),
  store('Store'),
  other('Other');

  final String displayName;
  const ClothingSource(this.displayName);
}

enum ClothingCondition {
  newCondition('New', Icons.star),
  likeNew('Like New', Icons.sentiment_very_satisfied),
  ok('Ok', Icons.sentiment_satisfied),
  bad('Bad', Icons.sentiment_dissatisfied);

  final String displayName;
  final IconData icon;
  const ClothingCondition(this.displayName, this.icon);
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
  final ClothingSource? source;
  final ClothingCondition? condition;
  final bool isTradeable;
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
    this.source,
    this.condition,
    this.isTradeable = false,
    this.isFavorite = false,
  });
}
