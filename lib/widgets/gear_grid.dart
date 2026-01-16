import 'dart:io';
import 'package:flutter/material.dart';
import '../data/clothing_item.dart';

class GearGrid extends StatefulWidget {
  final List<ClothingItem> items;
  final void Function(ClothingItem)? onItemTap;

  const GearGrid({super.key, required this.items, this.onItemTap});

  @override
  State<GearGrid> createState() => _GearGridState();
}

class _GearGridState extends State<GearGrid> {
  double _crossAxisCount = 2.0;
  double _scaleStartCrossAxisCount = 2.0;

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartCrossAxisCount = _crossAxisCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final orientation = MediaQuery.of(context).orientation;
    final minCols = orientation == Orientation.landscape ? 2.0 : 1.0;

    setState(() {
      _crossAxisCount = (_scaleStartCrossAxisCount / details.scale).clamp(
        minCols,
        5.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          "Wardrobe is empty",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
    }
    
    final orientation = MediaQuery.of(context).orientation;
    final minCols = orientation == Orientation.landscape ? 2.0 : 1.0;
    if (_crossAxisCount < minCols) {
      _crossAxisCount = minCols;
    }

    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: GridView.builder(
        itemCount: widget.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount.round(),
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _buildGearCard(item);
        },
      ),
    );
  }

  Widget _buildGearCard(ClothingItem item) {
    final bool hideText = _crossAxisCount.round() >= 3;

    final bool hasChips =
        item.size != null ||
        item.isFavorite ||
        item.isTradeable ||
        item.condition != null;

    final bool showFooter = !hideText && hasChips;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => widget.onItemTap?.call(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.withValues(alpha: 0.2),
                child: item.frontImage.isNotEmpty
                    ? (item.frontImage.startsWith('http')
                        ? Image.network(
                            item.frontImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.checkroom,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(item.frontImage),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.checkroom,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                              );
                            },
                          ))
                    : Center(
                        child: Icon(
                          Icons.checkroom,
                          size: 48,
                          color: Colors.white60,
                        ),
                      ),
              ),
            ),
  
            if (showFooter)
              Container(
                color: Colors.grey.withValues(alpha: 0.2),
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: [
                    if (item.isTradeable)
                      Chip(
                        label: Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: Colors.blue,
                        ),
                        side: BorderSide(color: Colors.blue),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (item.isFavorite)
                      Chip(
                        label: Icon(Icons.favorite, size: 16, color: Colors.red),
                        side: BorderSide(color: Colors.red),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (item.size != null)
                      Chip(
                        label: Text(
                          item.size!.name.toUpperCase(),
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        side: BorderSide(color: Colors.green),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (item.condition != null)
                      Chip(
                        label: Icon(
                          item.condition!.icon,
                          size: 16,
                          color: Colors.grey,
                        ),
                        side: BorderSide(color: Colors.grey),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
