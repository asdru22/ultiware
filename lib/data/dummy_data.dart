import 'clothing_item.dart';

final List<ClothingItem> dummyGear = [
  ClothingItem(
    id: '1',
    name: 'Dark Jersey',
    type: ClothingType.jersey,
    frontImage: '',
    size: ClothingSize.m,
    brand: ClothingBrand.a,
    productionYear: 2023,
  ),
  ClothingItem(
    id: '2',
    name: 'Light Jersey',
    type: ClothingType.jersey,
    frontImage: '',
    size: ClothingSize.l,
    brand: ClothingBrand.a,
    productionYear: 2022,
  ),
  ClothingItem(
    id: '3',
    name: 'Layout Gloves',
    // type: 'Accessories', // No enum for accessories yet, treating as null or generic
    frontImage: '',
    brand: ClothingBrand.c,
  ),
  ClothingItem(
    id: '4', 
    name: 'Club Shorts', 
    type: ClothingType.shorts, 
    frontImage: '',
    size: ClothingSize.m,
  ),
  ClothingItem(
    id: '5',
    name: 'Tourney Hoodie',
    // type: 'Outerwear', 
    frontImage: '',
    size: ClothingSize.xl,
    productionYear: 2024,
  ),
  ClothingItem(
    id: '6', 
    name: 'Disc', 
    // type: 'Gear', 
    frontImage: '',
    brand: ClothingBrand.d,
  ),
];
