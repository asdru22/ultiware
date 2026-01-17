import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/clothing_repository.dart';
import '../data/clothing_item.dart';
import '../data/trade.dart';
import 'package:intl/intl.dart';
import 'gear_detail_screen.dart';

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

          final sortedTrades = List<Trade>.from(trades)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: sortedTrades.length,
            itemBuilder: (context, index) {
              final trade = sortedTrades[index];

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat.yMMMd().add_jm().format(trade.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Trade'),
                                  content: const Text(
                                    'Are you sure you want to delete this trade from your history? The items will not be affected.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                repo.deleteTrade(trade);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              children: givenItems
                                  .map(
                                    (i) => InkWell(
                                      onTap: i != null
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => Scaffold(
                                                    appBar: AppBar(
                                                      title: Text(
                                                        i.name ??
                                                            "Item Details",
                                                      ),
                                                      leading:
                                                          const CloseButton(),
                                                    ),
                                                    body: GearDetailContent(
                                                      item: i,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      child: _buildItemThumbnail(i),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

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
                              ],
                            ),
                          ),

                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              children: receivedItems
                                  .map(
                                    (i) => InkWell(
                                      onTap: i != null
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => Scaffold(
                                                    appBar: AppBar(
                                                      title: Text(
                                                        i.name ??
                                                            "Item Details",
                                                      ),
                                                      leading:
                                                          const CloseButton(),
                                                    ),
                                                    body: GearDetailContent(
                                                      item: i,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      child: _buildItemThumbnail(i),
                                    ),
                                  )
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
