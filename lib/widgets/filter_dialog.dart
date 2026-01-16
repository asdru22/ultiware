import 'package:flutter/material.dart';
import '../data/clothing_item.dart';
import '../utils/filter_criteria.dart';

class FilterDialog extends StatefulWidget {
  final FilterCriteria initialCriteria;

  const FilterDialog({super.key, required this.initialCriteria});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late FilterCriteria _criteria;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clone logic: create a new object with values from initial
    _criteria = FilterCriteria(
      searchQuery: widget.initialCriteria.searchQuery,
      size: widget.initialCriteria.size,
      brand: widget.initialCriteria.brand,
      type: widget.initialCriteria.type,
      countryOfOrigin: widget.initialCriteria.countryOfOrigin,
      productionYear: widget.initialCriteria.productionYear,
      source: widget.initialCriteria.source,
      condition: widget.initialCriteria.condition,
      isTradeable: widget.initialCriteria.isTradeable,
      isFavorite: widget.initialCriteria.isFavorite,
    );

    _searchController.text = _criteria.searchQuery ?? '';
    _countryController.text = _criteria.countryOfOrigin ?? '';
    _yearController.text = _criteria.productionYear?.toString() ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _countryController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter & Search'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Search by Name
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _criteria.searchQuery = value.isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 16),

            // Enums Dropdowns
            _buildDropdown<ClothingBrand>(
              'Brand',
              ClothingBrand.values,
              _criteria.brand,
              (val) => setState(() => _criteria.brand = val),
              (val) => val.displayName,
            ),
            _buildDropdown<ClothingType>(
              'Type',
              ClothingType.values,
              _criteria.type,
              (val) => setState(() => _criteria.type = val),
              (val) => val.displayName,
            ),
            _buildDropdown<ClothingSize>(
              'Size',
              ClothingSize.values,
              _criteria.size,
              (val) => setState(() => _criteria.size = val),
              (val) => val.name.toUpperCase(),
            ),
            _buildDropdown<ClothingSource>(
              'Source',
              ClothingSource.values,
              _criteria.source,
              (val) => setState(() => _criteria.source = val),
              (val) => val.displayName,
            ),
            _buildDropdown<ClothingCondition>(
              'Condition',
              ClothingCondition.values,
              _criteria.condition,
              (val) => setState(() => _criteria.condition = val),
              (val) => val.displayName,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country of Origin'),
              onChanged: (value) {
                _criteria.countryOfOrigin = value.isEmpty ? null : value;
              },
            ),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Production Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _criteria.productionYear = int.tryParse(value);
              },
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),
            const Text("Status"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _criteria.isTradeable != true && _criteria.isFavorite != true,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _criteria.isTradeable = null;
                        _criteria.isFavorite = null;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Tradeable'),
                  selected: _criteria.isTradeable == true,
                  onSelected: (bool selected) {
                     setState(() {
                        if (selected) {
                          _criteria.isTradeable = true;
                          _criteria.isFavorite = null;
                        } else {
                           // If deselecting, go back to All? Or just clear this one?
                           // Usually radio behavior implies one must be selected.
                           // If toggle behavior, then deselecting goes to "All" implicitly (both null).
                           _criteria.isTradeable = null;
                        }
                      });
                  },
                ),
                ChoiceChip(
                  label: const Text('Favorite'),
                  selected: _criteria.isFavorite == true,
                  onSelected: (bool selected) {
                     setState(() {
                        if (selected) {
                          _criteria.isFavorite = true;
                          _criteria.isTradeable = null;
                        } else {
                           _criteria.isFavorite = null;
                        }
                      });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear all
            setState(() {
              _criteria = FilterCriteria();
              _searchController.clear();
              _countryController.clear();
              _yearController.clear();
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _criteria);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
    String label,
    List<T> values,
    T? currentValue,
    ValueChanged<T?> onChanged,
    String Function(T) labelBuilder,
  ) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(labelText: label),
      initialValue: currentValue,
      items: [
        DropdownMenuItem<T>(value: null, child: const Text('Any')),
        ...values.map(
          (v) => DropdownMenuItem<T>(value: v, child: Text(labelBuilder(v))),
        ),
      ],
      onChanged: onChanged,
    );
  }


}
