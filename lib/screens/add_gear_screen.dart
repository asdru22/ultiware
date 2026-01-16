import 'dart:io';

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../data/clothing_item.dart';
import 'custom_image_picker.dart';
import '../widgets/selection_screen.dart';

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
  ClothingSource? _source;
  ClothingCondition? _condition;
  String? _country;
  int? _year;
  bool _isFavorite = false;
  bool _isTradeable = false;

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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomImagePicker()),
    );

    if (result != null && result is Map) {
      String imagePath = result['path'];
      final String source = result['source'];

      if (source == 'camera') {
        // Copy to permanent storage
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(imagePath);
        final String newPath = path.join(directory.path, fileName);
        await File(imagePath).copy(newPath);
        imagePath = newPath;
      }

      setState(() {
        if (isFront) {
          _frontImage = imagePath;
        } else {
          _backImage = imagePath;
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
        source: _source,
        condition: _condition,
        isTradeable: _isTradeable,
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

            if (_type != ClothingType.neckie &&
                _type != ClothingType.socks &&
                _type != ClothingType.gloves) ...[
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
            ],

            // Brand (Selection Screen)
            TextFormField(
              controller: TextEditingController(
                text: _brand?.displayName ?? '',
              ),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.branding_watermark),
                // Or any suitable icon
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectionScreen<ClothingBrand>(
                      title: 'Select Brand',
                      items: ClothingBrand.values,
                      itemLabelBuilder: (brand) => brand.displayName,
                      onSelected: (brand) {
                        setState(() {
                          _brand = brand;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Type (Selection Screen)
            TextFormField(
              controller: TextEditingController(text: _type?.displayName ?? ''),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category), // Or any suitable icon
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectionScreen<ClothingType>(
                      title: 'Select Type',
                      items: ClothingType.values,
                      itemLabelBuilder: (type) => type.displayName,
                      onSelected: (type) {
                        setState(() {
                          _type = type;
                          if (_type == ClothingType.neckie ||
                              _type == ClothingType.socks ||
                              _type == ClothingType.gloves) {
                            _size = null;
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Source (Dropdown)
            DropdownMenu<ClothingSource>(
              width: MediaQuery.of(context).size.width - 32,
              initialSelection: _source,
              label: const Text('Source'),
              dropdownMenuEntries: ClothingSource.values.map((source) {
                return DropdownMenuEntry<ClothingSource>(
                  value: source,
                  label: source.displayName,
                );
              }).toList(),
              onSelected: (ClothingSource? source) {
                setState(() {
                  _source = source;
                });
              },
            ),
            const SizedBox(height: 16),

            // Condition (Dropdown)
            DropdownMenu<ClothingCondition>(
              width: MediaQuery.of(context).size.width - 32,
              initialSelection: _condition,
              label: const Text('Condition'),
              dropdownMenuEntries: ClothingCondition.values.map((condition) {
                return DropdownMenuEntry<ClothingCondition>(
                  value: condition,
                  label: condition.displayName,
                  leadingIcon: Icon(condition.icon),
                );
              }).toList(),
              onSelected: (ClothingCondition? condition) {
                setState(() {
                  _condition = condition;
                });
              },
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
              validator: (value) => null, // Optional now
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
                  if (_isFavorite) {
                    _isTradeable = false;
                  }
                });
              },
              secondary: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 8),

            // Tradeable Switch
            SwitchListTile(
              title: const Text('Mark as Tradeable'),
              value: _isTradeable,
              onChanged: (bool value) {
                setState(() {
                  _isTradeable = value;
                  if (_isTradeable) {
                    _isFavorite = false;
                  }
                });
              },
              secondary: Icon(
                Icons.swap_horiz,
                color: _isTradeable ? Colors.blue : null,
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
