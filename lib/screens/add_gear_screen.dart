import 'package:flutter/material.dart';
import '../data/clothing_item.dart';
import '../widgets/gear_form.dart';

class AddGearScreen extends StatefulWidget {
  final ClothingItem? itemToEdit;

  const AddGearScreen({super.key, this.itemToEdit});

  @override
  State<AddGearScreen> createState() => _AddGearScreenState();
}

class _AddGearScreenState extends State<AddGearScreen> {
  final _gearFormKey = GlobalKey<GearFormState>();

  void _saveItem() {
    final newItem = _gearFormKey.currentState!.validateAndGetItem();
    if (newItem != null) {
      Navigator.pop(context, newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit != null ? 'Edit Gear' : 'Add New Gear'),
      ),
      body: GearForm(
        key: _gearFormKey,
        initialItem: widget.itemToEdit,
        footer: FilledButton.icon(
          onPressed: _saveItem,
          icon: const Icon(Icons.save),
          label: Text(widget.itemToEdit != null ? 'Save Changes' : 'Save Gear'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
