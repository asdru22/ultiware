import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../clothing_item.dart';

class LocalDataSource {
  Future<List<ClothingItem>> fetchItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gear_items.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        return jsonList.map((item) => ClothingItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Error loading items from local: $e");
    }
    return [];
  }

  Future<void> saveItems(List<ClothingItem> items) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/gear_items.json');
      final String contents = jsonEncode(
        items.map((item) => item.toJson()).toList(),
      );
      await file.writeAsString(contents);
    } catch (e) {
      debugPrint("Error saving items locally: $e");
    }
  }

  Future<void> deleteOrphanedImages(List<ClothingItem> currentItems) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      for (var entity in files) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          if (filename.endsWith('_front.jpg') ||
              filename.endsWith('_back.jpg')) {
            bool isReferenced = false;
            for (var item in currentItems) {
              if ((item.frontImage.isNotEmpty &&
                      item.frontImage.endsWith(filename)) ||
                  (item.backImage != null &&
                      item.backImage!.isNotEmpty &&
                      item.backImage!.endsWith(filename))) {
                isReferenced = true;
                break;
              }
            }

            if (!isReferenced) {
              try {
                await entity.delete();
                debugPrint("Deleted orphaned image: $filename");
              } catch (e) {
                debugPrint("Error deleting orphan: $e");
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error cleaning up images: $e");
    }
  }
}
