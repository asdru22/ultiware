import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/clothing_repository.dart';
import '../data/clothing_item.dart';
import '../data/trade.dart';
import 'package:intl/intl.dart';

class TradeHistoryScreen extends StatelessWidget {
  const TradeHistoryScreen({super.key});

  Widget _buildItemThumbnail(ClothingItem? item) {
    if (item == null) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey.withValues(alpha: 0.2),
        child: const Icon(Icons.help_outline, color: Colors.grey),
      );
    }

    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.frontImage.isNotEmpty
            ? (item.frontImage.startsWith('http')
                  ? Image.network(
                      item.frontImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.error),
                    )
                  : Image.file(
                      File(item.frontImage),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.error),
                    ))
            : const Icon(Icons.image_not_supported),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade History')),
      body: Consumer<ClothingRepository>(
        builder: (context, repo, child) {
          final trades = repo.trades;

          if (trades.isEmpty) {
            return const Center(
              child: Text(
                "No trades yet.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Sort trades by date descending (repo might not guarantee it)
          final sortedTrades = List<Trade>.from(trades)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: sortedTrades.length,
            itemBuilder: (context, index) {
              final trade = sortedTrades[index];

              // Resolve items
              final givenItems = trade.givenItemIds.map((id) {
                try {
                  return repo.items.firstWhere((item) => item.id == id);
                } catch (_) {
                  return null;
                }
              }).toList();

              final receivedItems = trade.receivedItemIds.map((id) {
                try {
                  return repo.items.firstWhere((item) => item.id == id);
                } catch (_) {
                  return null;
                }
              }).toList();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMd().add_jm().format(trade.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // GIVEN items
                          Expanded(
                            child: Wrap(
                              children: givenItems
                                  .map((i) => _buildItemThumbnail(i))
                                  .toList(),
                            ),
                          ),

                          // Arrow
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 32,
                                  color: Colors.blue,
                                ),
                                Text(
                                  "Gave",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              children: receivedItems
                                  .map((i) => _buildItemThumbnail(i))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
