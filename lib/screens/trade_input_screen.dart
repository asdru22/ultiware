import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/clothing_item.dart';
import '../data/clothing_repository.dart';
import '../widgets/gear_form.dart';

class TradeInputScreen extends StatefulWidget {
  final List<ClothingItem> givenItems;

  const TradeInputScreen({super.key, required this.givenItems});

  @override
  State<TradeInputScreen> createState() => _TradeInputScreenState();
}

class _TradeInputScreenState extends State<TradeInputScreen> {
  final _gearFormKey = GlobalKey<GearFormState>();
  final List<ClothingItem> _receivedItems = [];

  void _addAnotherItem() {
    final item = _gearFormKey.currentState!.validateAndGetItem();
    if (item != null) {
      setState(() {
        _receivedItems.add(item);
        _gearFormKey.currentState!.reset();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item added to trade!')));
    }
  }

  Future<void> _finalizeTrade() async {
    // Check if there is a pending item in the form
    if (_gearFormKey.currentState!.hasFrontImage) {
      final item = _gearFormKey.currentState!.validateAndGetItem();
      if (item != null) {
        _receivedItems.add(item);
      }
    }

    if (_receivedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must receive at least one item!')),
      );
      return;
    }

    await Provider.of<ClothingRepository>(
      context,
      listen: false,
    ).performTrade(widget.givenItems, _receivedItems);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Items'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "${_receivedItems.length} Added",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: GearForm(key: _gearFormKey)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addAnotherItem,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Add Another Item"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _finalizeTrade,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Finalize Trade"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
