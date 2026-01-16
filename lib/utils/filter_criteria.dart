import '../data/clothing_item.dart';

class FilterCriteria {
  String? searchQuery;
  ClothingSize? size;
  ClothingBrand? brand;
  ClothingType? type;
  String? countryOfOrigin;
  int? productionYear;
  ClothingSource? source;
  ClothingCondition? condition;
  bool? isTradeable;
  bool? isFavorite;

  FilterCriteria({
    this.searchQuery,
    this.size,
    this.brand,
    this.type,
    this.countryOfOrigin,
    this.productionYear,
    this.source,
    this.condition,
    this.isTradeable,
    this.isFavorite,
  });

  bool matches(ClothingItem item) {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      if (!(item.name?.toLowerCase().contains(searchQuery!.toLowerCase()) ?? false)) {
        return false;
      }
    }

    if (size != null && item.size != size) return false;
    if (brand != null && item.brand != brand) return false;
    if (type != null && item.type != type) return false;
    
    if (countryOfOrigin != null && countryOfOrigin!.isNotEmpty) {
      if (item.countryOfOrigin != countryOfOrigin) return false; 
      // Exact match for country for now, or could change to contains
    }

    if (productionYear != null && item.productionYear != productionYear) return false;
    
    if (source != null && item.source != source) return false;
    if (condition != null && item.condition != condition) return false;
    
    if (isTradeable != null && item.isTradeable != isTradeable) return false;
    if (isFavorite != null && item.isFavorite != isFavorite) return false;

    return true;
  }
  
  FilterCriteria copyWith({
    String? searchQuery,
    ClothingSize? size,
    ClothingBrand? brand,
    ClothingType? type,
    String? countryOfOrigin,
    int? productionYear,
    ClothingSource? source,
    ClothingCondition? condition,
    bool? isTradeable,
    bool? isFavorite,
  }) {
    return FilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      productionYear: productionYear ?? this.productionYear,
      source: source ?? this.source,
      condition: condition ?? this.condition,
      isTradeable: isTradeable ?? this.isTradeable,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
