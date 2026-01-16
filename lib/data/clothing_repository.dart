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
    notifyListeners();
    syncToCloud();
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
      final file = File('${directory.path}/gear_items.json');
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
    await _saveLocalItems();
    syncToCloud();
  }

  Future<void> removeItem(ClothingItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
    await _saveLocalItems();
    syncToCloud();
  }

  void updateItem(ClothingItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
      _saveLocalItems();
      syncToCloud();
    }
  }

  Future<void> syncToCloud() async {
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
}
