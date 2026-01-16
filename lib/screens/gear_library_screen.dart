import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/clothing_item.dart';
import '../data/clothing_repository.dart';
import '../widgets/gear_grid.dart';
import 'add_gear_screen.dart';
import 'gear_detail_screen.dart';

class GearLibraryScreen extends StatefulWidget {
  const GearLibraryScreen({super.key});

  @override
  State<GearLibraryScreen> createState() => _GearLibraryScreenState();
}

class _GearLibraryScreenState extends State<GearLibraryScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ultiware'),
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
            icon: const Icon(Icons.sort),
            onPressed: () {
              debugPrint("Sort Items");
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              debugPrint("Search Items");
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Consumer<ClothingRepository>(
          builder: (context, repo, child) {
            final user = repo.driveService.currentUser;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(user?.displayName ?? "Not Signed In"),
                  accountEmail: Text(
                    user?.email ?? "Sign in to sync with Drive",
                  ),
                  currentAccountPicture: user?.photoUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (repo.isSignedIn) ...[
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('Sync Now'),
                    onTap: () {
                      repo.syncToCloud();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing to Drive...')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      repo.signOut();
                      Navigator.pop(context);
                    },
                  ),
                ] else
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign In with Google'),
                    onTap: () {
                      repo.signIn();
                      Navigator.pop(context);
                    },
                  ),
              ],
            );
          },
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
          child: Consumer<ClothingRepository>(
            builder: (context, repo, child) {
              if (repo.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (repo.items.isEmpty) {
                return const Center(
                  child: Text("No items yet. Add some gear!"),
                );
              }
              return GearGrid(
                items: repo.items,
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
  }
}
