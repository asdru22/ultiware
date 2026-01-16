import 'dart:io';
import 'package:flutter/material.dart';
import '../data/clothing_item.dart';

class GearDetailScreen extends StatefulWidget {
  final ClothingItem item;

  const GearDetailScreen({super.key, required this.item});

  @override
  State<GearDetailScreen> createState() => _GearDetailScreenState();
}

class _GearDetailScreenState extends State<GearDetailScreen> {
  final PageController _pageController = PageController();

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBackImage =
        widget.item.backImage != null && widget.item.backImage!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.of(context).pop(),
        ),
        title: Text(widget.item.name ?? 'Gear Details'),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _handleDelete),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive Image Display
            Builder(
              builder: (context) {
                final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                final screenHeight = MediaQuery.of(context).size.height;

                if (isLandscape) {
                  if (hasBackImage) {
                    return SizedBox(
                      height: screenHeight,
                      child: Row(
                        children: [
                          Expanded(child: _buildImage(widget.item.frontImage)),
                          Expanded(child: _buildImage(widget.item.backImage!)),
                        ],
                      ),
                    );
                  } else {
                    return SizedBox(
                      height: screenHeight,
                      width: double.infinity,
                      child: _buildImage(widget.item.frontImage),
                    );
                  }
                }

                // Portrait Carousel
                return SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        children: [
                          _buildImage(widget.item.frontImage),
                          if (hasBackImage) _buildImage(widget.item.backImage!),
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
                                Icon(Icons.circle, size: 8, color: Colors.white70),
                                SizedBox(width: 8),
                                Icon(Icons.circle, size: 8, color: Colors.white30),
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
                  _buildDetailRow("Brand", widget.item.brand?.displayName),
                  _buildDivider(),
                  _buildDetailRow("Type", widget.item.type?.displayName),
                  _buildDivider(),
                  if (widget.item.size != null) ...[
                    _buildDetailRow(
                      "Size",
                      widget.item.size!.name.toUpperCase(),
                    ),
                    _buildDivider(),
                  ],
                  _buildDetailRow("Source", widget.item.source?.displayName),
                  _buildDivider(),
                  _buildDetailRow(
                    "Condition",
                    widget.item.condition?.displayName,
                  ),
                  _buildDivider(),
                  _buildDetailRow("Country", widget.item.countryOfOrigin),
                  _buildDivider(),
                  if (widget.item.productionYear != null) ...[
                    _buildDetailRow(
                      "Year",
                      widget.item.productionYear.toString(),
                    ),
                    _buildDivider(),
                  ],
                  if (widget.item.isFavorite) ...[
                    _buildSwitchRow("Favorite", true, Colors.red),
                    _buildDivider(),
                  ],
                  if (widget.item.isTradeable) ...[
                    _buildSwitchRow("Tradeable", true, Colors.blue),
                    _buildDivider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
