import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import 'clothing_item.dart';
import 'datasources/local_data_source.dart';
import 'datasources/remote_data_source.dart';
import 'trade.dart';

class ClothingRepository extends ChangeNotifier {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  List<ClothingItem> _items = [];
  List<Trade> _trades = [];
  bool _isLoading = false;

  List<ClothingItem> get items => List.unmodifiable(_items);

  List<Trade> get trades => List.unmodifiable(_trades);

  bool get isLoading => _isLoading;

  bool get isSignedIn => _remoteDataSource.isSignedIn;

  RemoteDataSource get remoteDataSource => _remoteDataSource;

  ClothingRepository(this._remoteDataSource, this._localDataSource) {
    _loadLocalItems();
    _loadLocalTrades();
    _remoteDataSource.signInSilently().then((_) {
      notifyListeners();
    });
  }

  Future<void> signIn() async {
    await _remoteDataSource.signIn();
    await loadFromCloud();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    notifyListeners();
  }

  Future<void> _loadLocalItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _localDataSource.fetchItems();
    } catch (e) {
      debugPrint("Error loading items: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalTrades() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/trades.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _trades = jsonList.map((json) => Trade.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error loading trades: $e");
    }
  }

  Future<void> _saveLocalTrades() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/trades.json');
      final content = jsonEncode(_trades.map((t) => t.toJson()).toList());
      await file.writeAsString(content);
    } catch (e) {
      debugPrint("Error saving trades: $e");
    }
  }

  Future<void> _saveLocalItems() async {
    await _localDataSource.saveItems(_items);
  }

  Future<void> addItem(ClothingItem item) async {
    item.isSynced = false;
    _items.add(item);
    notifyListeners();
    await _saveLocalItems();
  }

  Future<void> removeItem(ClothingItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
    await _saveLocalItems();
  }

  void updateItem(ClothingItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      updatedItem.isSynced = false;
      _items[index] = updatedItem;
      notifyListeners();
      _saveLocalItems();
    }
  }

  Future<void> performTrade(
    List<ClothingItem> givenItems,
    List<ClothingItem> receivedItems,
  ) async {
    final trade = Trade(
      id: DateTime.now().toIso8601String(),
      date: DateTime.now(),
      givenItemIds: givenItems.map((i) => i.id).toList(),
      receivedItemIds: receivedItems.map((i) => i.id).toList(),
    );

    _trades.add(trade);
    await _saveLocalTrades();

    for (var item in givenItems) {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index].isTraded = true;
        _items[index].isSynced = false;
      }
    }

    for (var item in receivedItems) {
      item.isSynced = false;
      _items.add(item);
    }

    notifyListeners();
    await _saveLocalItems();
  }

  Future<void> deleteTrade(Trade trade) async {
    _trades.removeWhere((t) => t.id == trade.id);
    notifyListeners();
    await _saveLocalTrades();
  }

  Future<void> saveToCloud() async {
    if (!_remoteDataSource.isSignedIn) return;

    debugPrint("Starting background sync...");

    final jsonContent = jsonEncode(
      _items.map((item) => item.toJson()).toList(),
    );
    await _remoteDataSource.uploadJson(jsonContent, 'gear_items.json');

    final tradeJsonContent = jsonEncode(
      _trades.map((t) => t.toJson()).toList(),
    );
    await _remoteDataSource.uploadJson(tradeJsonContent, 'trades.json');

    final Map<String, File> filesToUpload = {};

    for (final item in _items) {
      if (item.frontImage.isNotEmpty) {
        final file = File(item.frontImage);
        if (await file.exists()) {
          filesToUpload['${item.id}_front.jpg'] = file;
        }
      }
      if (item.backImage != null && item.backImage!.isNotEmpty) {
        final file = File(item.backImage!);
        if (await file.exists()) {
          filesToUpload['${item.id}_back.jpg'] = file;
        }
      }
    }

    if (filesToUpload.isNotEmpty) {
      await _remoteDataSource.uploadFiles(filesToUpload);
    }

    debugPrint("Sync complete.");

    for (final item in _items) {
      item.isSynced = true;
    }
    await _saveLocalItems();
  }

  Future<void> loadFromCloud() async {
    if (!_remoteDataSource.isSignedIn) return;

    debugPrint("Loading from cloud...");
    try {
      final jsonContent = await _remoteDataSource.downloadJson(
        'gear_items.json',
      );
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

        await _localDataSource.deleteOrphanedImages(_items);
        await _downloadMissingImages();
      }

      final tradeJsonContent = await _remoteDataSource.downloadJson(
        'trades.json',
      );
      if (tradeJsonContent != null) {
        final List<dynamic> tradeList = jsonDecode(tradeJsonContent);
        final List<Trade> cloudTrades = tradeList
            .map((t) => Trade.fromJson(t))
            .toList();

        final Set<String> localDisplayIds = _trades.map((t) => t.id).toSet();
        for (var t in cloudTrades) {
          if (!localDisplayIds.contains(t.id)) {
            _trades.add(t);
          }
        }
        _trades.sort((a, b) => b.date.compareTo(a.date));
        await _saveLocalTrades();
      }
    } catch (e) {
      debugPrint("Error loading from cloud: $e");
    }
  }

  Future<void> _downloadMissingImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final Map<String, File> filesToDownload = {};

    for (var item in _items) {
      if (item.frontImage.isNotEmpty) {
        final file = File(item.frontImage);
        if (!await file.exists()) {
          final targetPath = '${directory.path}/${item.id}_front.jpg';
          final targetFile = File(targetPath);
          filesToDownload['${item.id}_front.jpg'] = targetFile;
          item.frontImage = targetPath;
        }
      }

      if (item.backImage != null && item.backImage!.isNotEmpty) {
        final file = File(item.backImage!);
        if (!await file.exists()) {
          final targetPath = '${directory.path}/${item.id}_back.jpg';
          final targetFile = File(targetPath);
          filesToDownload['${item.id}_back.jpg'] = targetFile;
          item.backImage = targetPath;
        }
      }
    }

    if (filesToDownload.isNotEmpty) {
      await _remoteDataSource.downloadFiles(filesToDownload);
    }

    await _saveLocalItems();
    notifyListeners();
  }
}
