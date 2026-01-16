import 'dart:io';

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../data/clothing_item.dart';
import 'custom_image_picker.dart';

class AddGearScreen extends StatefulWidget {
  const AddGearScreen({super.key});

  @override
  State<AddGearScreen> createState() => _AddGearScreenState();
}

class _AddGearScreenState extends State<AddGearScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String? _frontImage;
  String? _backImage;
  String? _name;
  ClothingSize? _size;
  ClothingBrand? _brand;
  ClothingType? _type;
  String? _country;
  int? _year;
  bool _isFavorite = false;

  // Controllers
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  void dispose() {
    _countryController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final String? pickedPath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomImagePicker()),
    );

    if (pickedPath != null) {
      setState(() {
        if (isFront) {
          _frontImage = pickedPath;
        } else {
          _backImage = pickedPath;
        }
      });
    }
  }

  Future<void> _pickYear() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
              selectedDate: _year != null ? DateTime(_year!) : DateTime.now(),
              onChanged: (DateTime dateTime) {
                setState(() {
                  _year = dateTime.year;
                  _yearController.text = _year.toString();
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      if (_frontImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Front picture is required!')),
        );
        return;
      }

      _formKey.currentState!.save();

      final newItem = ClothingItem(
        id: DateTime.now().toString(),
        frontImage: _frontImage!,
        backImage: _backImage,
        name: _name,
        size: _size,
        brand: _brand,
        type: _type,
        countryOfOrigin: _country,
        productionYear: _year,
        isFavorite: _isFavorite,
      );

      Navigator.pop(context, newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Gear')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              children: [
                Expanded(child: _buildImagePicker(true)),
                const SizedBox(width: 16),
                Expanded(child: _buildImagePicker(false)),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _name = value,
            ),
            const SizedBox(height: 16),

            Text('Size', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ClothingSize>(
              showSelectedIcon: false,
              segments: ClothingSize.values.map((size) {
                return ButtonSegment<ClothingSize>(
                  value: size,
                  label: Text(size.name.toUpperCase()),
                );
              }).toList(),
              selected: _size != null ? {_size!} : {},
              onSelectionChanged: (Set<ClothingSize> newSelection) {
                setState(() {
                  _size = newSelection.first;
                });
              },
              emptySelectionAllowed: true,
            ),
            const SizedBox(height: 16),

            // Brand (Choice Chips)
            Text('Brand', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: ClothingBrand.values.map((brand) {
                return ChoiceChip(
                  label: Text(brand.displayName),
                  selected: _brand == brand,
                  onSelected: (bool selected) {
                    setState(() {
                      _brand = selected ? brand : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Type (Choice Chips)
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: ClothingType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: _type == type,
                  onSelected: (bool selected) {
                    setState(() {
                      _type = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Country (Picker)
            TextFormField(
              controller: _countryController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Country of Origin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: false,
                  onSelect: (Country country) {
                    setState(() {
                      _country = country.name;
                      _countryController.text =
                          "${country.flagEmoji} ${country.name}";
                    });
                  },
                );
              },
              validator: (value) =>
                  _country == null ? 'Please select a country' : null,
            ),
            const SizedBox(height: 16),

            // Year Picker
            TextFormField(
              controller: _yearController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Production Year',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: _pickYear,
            ),
            const SizedBox(height: 16),

            // Favorite Switch
            SwitchListTile(
              title: const Text('Mark as Favorite'),
              value: _isFavorite,
              onChanged: (bool value) {
                setState(() {
                  _isFavorite = value;
                });
              },
              secondary: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _saveItem,
              icon: const Icon(Icons.save),
              label: const Text('Save Gear'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isFront) {
    final imagePath = isFront ? _frontImage : _backImage;
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFront && imagePath == null
                ? Theme.of(context).colorScheme.error
                : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath), fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.check, size: 16, color: Colors.green),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFront ? Icons.camera_front : Icons.camera_rear,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFront ? 'Front (Req)' : 'Back (Opt)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
