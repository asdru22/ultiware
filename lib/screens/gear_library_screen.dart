import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../data/clothing_item.dart';
import '../data/clothing_repository.dart';
import '../widgets/gear_grid.dart';
import 'add_gear_screen.dart';
import 'gear_detail_screen.dart';
import 'account_screen.dart';
import '../utils/filter_criteria.dart';
import '../widgets/filter_dialog.dart';
import 'export_data_screen.dart';
import 'trade_input_screen.dart';
import 'trade_history_screen.dart';
import 'statistics_screen.dart';

class GearLibraryScreen extends StatefulWidget {
  const GearLibraryScreen({super.key});

  @override
  State<GearLibraryScreen> createState() => _GearLibraryScreenState();
}

class _GearLibraryScreenState extends State<GearLibraryScreen> {
  final Set<String> _selectedItems = {};
  bool _isTradeMode = false;
  
  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  FilterCriteria _filterCriteria = FilterCriteria();
  bool _isOnline = true;

  Future<void> _checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _isOnline = false;
      });
    } else {
      setState(() {
        _isOnline = true;
      });
    }

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (mounted) {
        setState(() {
          _isOnline = !result.contains(ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _addItem(BuildContext context) async {
    final newItem = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGearScreen()),
    );

    if (newItem != null && newItem is ClothingItem) {
      if (context.mounted) {
        await Provider.of<ClothingRepository>(
          context,
          listen: false,
        ).addItem(newItem);
      }
    }
  }

  void _enterTradeMode(ClothingItem initialItem) {
    setState(() {
      _isTradeMode = true;
      _selectedItems.clear();
      _selectedItems.add(initialItem.id);
    });
  }

  void _exitTradeMode() {
    setState(() {
      _isTradeMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelection(ClothingItem item) {
    setState(() {
      if (_selectedItems.contains(item.id)) {
        _selectedItems.remove(item.id);
        if (_selectedItems.isEmpty) {
          _isTradeMode = false;
        }
      } else {
        _selectedItems.add(item.id);
      }
    });
  }

  Future<void> _proceedToTradeInput(List<ClothingItem> allItems) async {
    final selectedObjects = allItems.where((i) => _selectedItems.contains(i.id)).toList();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TradeInputScreen(givenItems: selectedObjects),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trade completed successfully!")),
        );
        _exitTradeMode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClothingRepository>(
      builder: (context, repo, child) {
        final activeItems = repo.items.where((item) => !item.isTraded).toList();

        final filteredItems = activeItems.where((item) {
          return _filterCriteria.matches(item);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(_isTradeMode
                ? "${_selectedItems.length} Selected"
                : '${filteredItems.length} Items'),
            centerTitle: true,
            leading: _isTradeMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitTradeMode,
                  )
                : Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
            actions: [
              if (_isTradeMode)
                TextButton(
                  onPressed: _selectedItems.isNotEmpty 
                      ? () => _proceedToTradeInput(activeItems) 
                      : null,
                  child: const Text("Select Trade Items", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () async {
                    final result = await showDialog<FilterCriteria>(
                      context: context,
                      builder: (context) =>
                          FilterDialog(initialCriteria: _filterCriteria),
                    );

                    if (result != null) {
                      setState(() {
                        _filterCriteria = result;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    repo.remoteDataSource.currentUser?.displayName ??
                        "Not Signed In",
                  ),
                  accountEmail: Text(
                    repo.remoteDataSource.currentUser?.email ??
                        "Sign in to sync with Drive",
                  ),
                  currentAccountPicture:
                      repo.remoteDataSource.currentUser?.photoUrl != null
                      ? CircleAvatar(
                          backgroundColor: Colors.black,
                          backgroundImage: NetworkImage(
                            repo.remoteDataSource.currentUser!.photoUrl!,
                          ),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  decoration: BoxDecoration(color: Colors.grey[900]),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: const Text('Account'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Data'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportDataScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_edu),
                  title: const Text('Trade History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TradeHistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          drawerEnableOpenDragGesture: !_isTradeMode,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _isTradeMode ? null : FloatingActionButton.extended(
            onPressed: () => _addItem(context),
            icon: const Icon(Icons.add),
            label: const Text("Add Gear"),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Builder(
                builder: (context) {
                  if (repo.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (repo.items.isEmpty) {
                    return const Center(
                      child: Text("No items yet. Add some gear!"),
                    );
                  }

                  if (filteredItems.isEmpty) {
                    return const Center(
                      child: Text("No items match your filter."),
                    );
                  }
                  return GearGrid(
                    items: filteredItems,
                    selectionMode: _isTradeMode,
                    selectedItemIds: _selectedItems,
                    onItemLongPress: (item) {
                       if (!_isTradeMode) {
                         _enterTradeMode(item);
                       }
                    },
                    onItemTap: (item) async {
                      if (_isTradeMode) {
                        _toggleSelection(item);
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GearDetailScreen(item: item),
                          ),
                        );

                        if (result == true) {
                          if (context.mounted) {
                            await repo.removeItem(item);
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
