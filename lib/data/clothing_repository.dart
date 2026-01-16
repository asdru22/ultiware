import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'clothing_item.dart';
import 'google_drive_service.dart';

class ClothingRepository extends ChangeNotifier {
  final GoogleDriveService _driveService;
  List<ClothingItem> _items = [];
  bool _isLoading = false;

  List<ClothingItem> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  bool get isSignedIn => _driveService.isSignedIn;

  GoogleDriveService get driveService => _driveService;

  ClothingRepository(this._driveService) {
    _loadLocalItems();
    _driveService.signInSilently().then((_) {
      notifyListeners();
    });
  }

  Future<void> signIn() async {
    await _driveService.signIn();
    await loadFromCloud();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _driveService.signOut();
    notifyListeners();
  }

  Future<void> _loadLocalItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gear_items.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        _items = jsonList.map((item) => ClothingItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Error loading items: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveLocalItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/gear_items.json');
      final String contents = jsonEncode(
        _items.map((item) => item.toJson()).toList(),
      );
      await file.writeAsString(contents);
    } catch (e) {
      debugPrint("Error saving items: $e");
    }
  }

  Future<void> addItem(ClothingItem item) async {
    item.isSynced = false;
    _items.add(item);
    notifyListeners();
    notifyListeners();
    await _saveLocalItems();
    saveToCloud();
  }

  Future<void> removeItem(ClothingItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
    await _saveLocalItems();
    saveToCloud();
  }

  void updateItem(ClothingItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      updatedItem.isSynced = false;
      _items[index] = updatedItem;
      notifyListeners();
      _saveLocalItems();
      saveToCloud();
    }
  }

  Future<void> saveToCloud() async {
    if (!_driveService.isSignedIn) return;

    debugPrint("Starting background sync...");

    final jsonContent = jsonEncode(
      _items.map((item) => item.toJson()).toList(),
    );
    await _driveService.uploadJson(jsonContent, 'gear_items.json');

    for (final item in _items) {
      if (item.frontImage.isNotEmpty) {
        final file = File(item.frontImage);
        if (await file.exists()) {
          final filename = '${item.id}_front.jpg';
          final success = await _driveService.uploadFile(file, filename);
          if (!success) {
            debugPrint("Failed to upload front image for ${item.id}");
          }
        }
      }
      if (item.backImage != null && item.backImage!.isNotEmpty) {
        final file = File(item.backImage!);
        if (await file.exists()) {
          final filename = '${item.id}_back.jpg';
          final success = await _driveService.uploadFile(file, filename);
          if (!success) {
            debugPrint("Failed to upload back image for ${item.id}");
          }
        }
      }
    }
    debugPrint("Sync complete.");

    for (final item in _items) {
      item.isSynced = true;
    }
    await _saveLocalItems();
  }

  Future<void> loadFromCloud() async {
    if (!_driveService.isSignedIn) return;

    debugPrint("Loading from cloud...");
    try {
      final jsonContent = await _driveService.downloadJson('gear_items.json');
      if (jsonContent != null) {
        final List<dynamic> jsonList = jsonDecode(jsonContent);
        final List<ClothingItem> cloudItems = jsonList.map((item) {
          final i = ClothingItem.fromJson(item);
          i.isSynced = true;
          return i;
        }).toList();

        final List<ClothingItem> newItems = List.from(cloudItems);

        for (final localItem in _items) {
          if (!localItem.isSynced) {
            final index = newItems.indexWhere((i) => i.id == localItem.id);
            if (index != -1) {
              newItems[index] = localItem;
            } else {
              newItems.add(localItem);
            }
          }
        }

        _items = newItems;
        notifyListeners();
        await _saveLocalItems();

        debugPrint("Cloud load complete. Items: ${_items.length}");

        await _deleteOrphanedImages();
        await _downloadMissingImages();
      }
    } catch (e) {
      debugPrint("Error loading from cloud: $e");
    }
  }

  Future<void> _downloadMissingImages() async {
    final directory = await getApplicationDocumentsDirectory();

    for (var item in _items) {
      if (item.frontImage.isNotEmpty) {
        final file = File(item.frontImage);
        if (!await file.exists()) {
          final targetPath = '${directory.path}/${item.id}_front.jpg';
          final targetFile = File(targetPath);

          final success = await _driveService.downloadFile(
            '${item.id}_front.jpg',
            targetFile,
          );

          if (success && await targetFile.exists()) {
            item.frontImage = targetPath;
          } else {
            debugPrint("Failed to download or find front image for ${item.id}");
          }
        }
      }

      if (item.backImage != null && item.backImage!.isNotEmpty) {
        final file = File(item.backImage!);
        if (!await file.exists()) {
          final targetPath = '${directory.path}/${item.id}_back.jpg';
          final targetFile = File(targetPath);

          final success = await _driveService.downloadFile(
            '${item.id}_back.jpg',
            targetFile,
          );

          if (success && await targetFile.exists()) {
            item.backImage = targetPath;
          } else {
            debugPrint("Failed to download or find back image for ${item.id}");
          }
        }
      }
    }
    await _saveLocalItems();
    notifyListeners();
  }

  Future<void> _deleteOrphanedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      for (var entity in files) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          if (filename.endsWith('_front.jpg') ||
              filename.endsWith('_back.jpg')) {
            bool isReferenced = false;
            for (var item in _items) {
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
