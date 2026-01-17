import 'dart:io';
import 'package:flutter/material.dart';
import '../data/clothing_item.dart';
import 'add_gear_screen.dart';
import 'package:provider/provider.dart';
import '../data/clothing_repository.dart';

class GearDetailScreen extends StatefulWidget {
  final ClothingItem item;

  const GearDetailScreen({super.key, required this.item});

  @override
  State<GearDetailScreen> createState() => _GearDetailScreenState();
}

class _GearDetailScreenState extends State<GearDetailScreen> {
  late ClothingItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _handleEdit() async {
    final updatedItem = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGearScreen(itemToEdit: _item)),
    );

    if (updatedItem != null && updatedItem is ClothingItem) {
      if (mounted) {
        Provider.of<ClothingRepository>(
          context,
          listen: false,
        ).updateItem(updatedItem);

        setState(() {
          _item = updatedItem;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item?'),
          content: const Text(
            'Are you sure you want to delete this item? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_item.name ?? 'Gear Details'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _handleEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _handleDelete),
        ],
      ),
      body: GearDetailContent(item: _item),
    );
  }
}

class GearDetailContent extends StatefulWidget {
  final ClothingItem item;

  const GearDetailContent({super.key, required this.item});

  @override
  State<GearDetailContent> createState() => _GearDetailContentState();
}

class _GearDetailContentState extends State<GearDetailContent> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool hasBackImage =
        item.backImage != null && item.backImage!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final isLandscape =
                  MediaQuery.of(context).orientation == Orientation.landscape;
              final screenHeight = MediaQuery.of(context).size.height;

              if (isLandscape) {
                if (hasBackImage) {
                  return SizedBox(
                    height: screenHeight,
                    child: Row(
                      children: [
                        Expanded(child: _buildImage(item.frontImage)),
                        Expanded(child: _buildImage(item.backImage!)),
                      ],
                    ),
                  );
                } else {
                  return SizedBox(
                    height: screenHeight,
                    width: double.infinity,
                    child: _buildImage(item.frontImage),
                  );
                }
              }

              return SizedBox(
                height: 400,
                child: Stack(
                  children: [
                    PageView(
                      controller: _pageController,
                      children: [
                        _buildImage(item.frontImage),
                        if (hasBackImage) _buildImage(item.backImage!),
                      ],
                    ),
                    if (hasBackImage)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.white30,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildDetailRow("Brand", item.brand?.displayName),
                _buildDivider(),
                _buildDetailRow("Type", item.type?.displayName),
                _buildDivider(),
                if (item.size != null) ...[
                  _buildDetailRow("Size", item.size!.name.toUpperCase()),
                  _buildDivider(),
                ],
                _buildDetailRow("Source", item.source?.displayName),
                _buildDivider(),
                _buildDetailRow("Condition", item.condition?.displayName),
                _buildDivider(),
                _buildDetailRow("Country", item.countryOfOrigin),
                _buildDivider(),
                if (item.productionYear != null) ...[
                  _buildDetailRow("Year", item.productionYear.toString()),
                  _buildDivider(),
                ],
                if (item.isFavorite) ...[
                  _buildSwitchRow("Favorite", true, Colors.red),
                  _buildDivider(),
                ],
                if (item.isTradeable) ...[
                  _buildSwitchRow("Tradeable", true, Colors.blue),
                  _buildDivider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, Color color) {
    if (!value) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Icon(Icons.check_circle, color: color, size: 24),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }
}
