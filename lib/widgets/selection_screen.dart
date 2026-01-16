import 'package:flutter/material.dart';

class SelectionScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final void Function(T) onSelected;

  const SelectionScreen({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabelBuilder,
    required this.onSelected,
  });

  @override
  State<SelectionScreen<T>> createState() => _SelectionScreenState<T>();
}

class _SelectionScreenState<T> extends State<SelectionScreen<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final label = widget.itemLabelBuilder(item).toLowerCase();
        return label.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Start typing to search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(widget.itemLabelBuilder(item)),
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
