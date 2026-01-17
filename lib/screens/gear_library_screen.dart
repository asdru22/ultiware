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

class GearLibraryScreen extends StatefulWidget {
  const GearLibraryScreen({super.key});

  @override
  State<GearLibraryScreen> createState() => _GearLibraryScreenState();
}

class _GearLibraryScreenState extends State<GearLibraryScreen> {
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

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ClothingRepository>(
      builder: (context, repo, child) {
        final filteredItems = repo.items.where((item) {
          return _filterCriteria.matches(item);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('${filteredItems.length} Items'),
            centerTitle: true,
            leading: Builder(
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
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    repo.driveService.currentUser?.displayName ??
                        "Not Signed In",
                  ),
                  accountEmail: Text(
                    repo.driveService.currentUser?.email ??
                        "Sign in to sync with Drive",
                  ),
                  currentAccountPicture:
                      repo.driveService.currentUser?.photoUrl != null
                      ? CircleAvatar(
                          backgroundColor: Colors.black,
                          backgroundImage: NetworkImage(
                            repo.driveService.currentUser!.photoUrl!,
                          ),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  decoration: BoxDecoration(color: Colors.grey[900]),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: const Text('Account'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
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
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportDataScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          drawerEnableOpenDragGesture: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton.extended(
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
                    onItemTap: (item) async {
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
                      } else if (result is ClothingItem) {}
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
