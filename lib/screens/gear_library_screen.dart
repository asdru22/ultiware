import 'package:flutter/material.dart';
import '../data/clothing_item.dart';
import '../widgets/gear_grid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'add_gear_screen.dart';
import 'gear_detail_screen.dart';

class GearLibraryScreen extends StatefulWidget {
  const GearLibraryScreen({super.key});

  @override
  State<GearLibraryScreen> createState() => _GearLibraryScreenState();
}

class _GearLibraryScreenState extends State<GearLibraryScreen> {
  final List<ClothingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gear_items.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        setState(() {
          _items.clear();
          _items.addAll(
            jsonList.map((item) => ClothingItem.fromJson(item)).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading items: $e");
    }
  }

  Future<void> _saveItems() async {
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

  Future<void> _addItem() async {
    final newItem = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGearScreen()),
    );

    if (newItem != null && newItem is ClothingItem) {
      setState(() {
        _items.add(newItem);
      });
      _saveItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ultiware'),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
                debugPrint("Open Menu");
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              debugPrint("Sort Items");
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              debugPrint("Search Items");
            },
          ),
        ],
      ),
      drawer: const Drawer(child: Center(child: Text("Menu Options Here"))),
      drawerEnableOpenDragGesture: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: Icon(Icons.add),
        label: Text("Add Gear"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GearGrid(
            items: _items,
            onItemTap: (item) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GearDetailScreen(item: item),
                ),
              );

              if (result == true) {
                setState(() {
                  _items.remove(item);
                });
                _saveItems();
              }
            },
          ),
        ),
      ),
    );
  }
}
