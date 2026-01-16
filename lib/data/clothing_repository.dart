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
    await loadFromCloud(); // Load data immediately after sign-in
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
          await _driveService.uploadFile(file, filename);
        }
      }
      if (item.backImage != null && item.backImage!.isNotEmpty) {
        final file = File(item.backImage!);
        if (await file.exists()) {
          final filename = '${item.id}_back.jpg';
          await _driveService.uploadFile(file, filename);
        }
      }
    }
    debugPrint("Sync complete.");
  }

  Future<void> loadFromCloud() async {
    if (!_driveService.isSignedIn) return;

    debugPrint("Loading from cloud...");
    try {
      final jsonContent = await _driveService.downloadJson('gear_items.json');
      if (jsonContent != null) {
        final List<dynamic> jsonList = jsonDecode(jsonContent);
        final List<ClothingItem> cloudItems = jsonList
            .map((item) => ClothingItem.fromJson(item))
            .toList();

        // Merge strategy: Overwrite local items with cloud items if IDs match.
        // Keep local items that are not in the cloud (optional, but safer).
        final Map<String, ClothingItem> itemMap = {
          for (var item in _items) item.id: item
        };

        for (var cloudItem in cloudItems) {
          itemMap[cloudItem.id] = cloudItem;
        }

        _items = itemMap.values.toList();
        notifyListeners();
        await _saveLocalItems();
        _items = itemMap.values.toList();
        notifyListeners();
        await _saveLocalItems();
        debugPrint("Cloud load complete. Items: ${_items.length}");

        // Now download images for items that need them
        await _downloadMissingImages();
      }
    } catch (e) {
      debugPrint("Error loading from cloud: $e");
    }
  }

  Future<void> _downloadMissingImages() async {
    final directory = await getApplicationDocumentsDirectory();

    for (var item in _items) {
      // Check Front Image
      if (item.frontImage.isNotEmpty) {
        final file = File(item.frontImage);
        if (!await file.exists()) {
          // If local path doesn't exist, try to download to a standard location
          // Using ID is a good way to keep filenames consistent across devices
          final targetPath = '${directory.path}/${item.id}_front.jpg';
          final targetFile = File(targetPath);

          await _driveService.downloadFile('${item.id}_front.jpg', targetFile);

          if (await targetFile.exists()) {
            item.frontImage =
                targetPath; // Update the path to the new local location
          }
        }
      }

      // Check Back Image
      if (item.backImage != null && item.backImage!.isNotEmpty) {
        final file = File(item.backImage!);
        if (!await file.exists()) {
          final targetPath = '${directory.path}/${item.id}_back.jpg';
          final targetFile = File(targetPath);

          await _driveService.downloadFile('${item.id}_back.jpg', targetFile);

          if (await targetFile.exists()) {
            item.backImage = targetPath;
          }
        }
      }
    }
    // Save updated paths
    await _saveLocalItems();
    notifyListeners();
  }
}
