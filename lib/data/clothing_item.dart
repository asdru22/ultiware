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

  String toJson() => name;
  static ClothingBrand fromJson(String json) => values.byName(json);
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

  String toJson() => name;
  static ClothingType fromJson(String json) => values.byName(json);
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

  String toJson() => name;
  static ClothingSource fromJson(String json) => values.byName(json);
}

enum ClothingCondition {
  newCondition('New', Icons.star),
  likeNew('Like New', Icons.sentiment_very_satisfied),
  ok('Ok', Icons.sentiment_satisfied),
  bad('Bad', Icons.sentiment_dissatisfied);

  final String displayName;
  final IconData icon;
  const ClothingCondition(this.displayName, this.icon);

  String toJson() => name;
  static ClothingCondition fromJson(String json) => values.byName(json);
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frontImage': frontImage,
      'backImage': backImage,
      'name': name,
      'size': size?.name,
      'brand': brand?.toJson(),
      'type': type?.toJson(),
      'countryOfOrigin': countryOfOrigin,
      'productionYear': productionYear,
      'source': source?.toJson(),
      'condition': condition?.toJson(),
      'isTradeable': isTradeable,
      'isFavorite': isFavorite,
    };
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      frontImage: json['frontImage'],
      backImage: json['backImage'],
      name: json['name'],
      size: json['size'] != null
          ? ClothingSize.values.byName(json['size'])
          : null,
      brand: json['brand'] != null
          ? ClothingBrand.fromJson(json['brand'])
          : null,
      type: json['type'] != null ? ClothingType.fromJson(json['type']) : null,
      countryOfOrigin: json['countryOfOrigin'],
      productionYear: json['productionYear'],
      source: json['source'] != null
          ? ClothingSource.fromJson(json['source'])
          : null,
      condition: json['condition'] != null
          ? ClothingCondition.fromJson(json['condition'])
          : null,
      isTradeable: json['isTradeable'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
