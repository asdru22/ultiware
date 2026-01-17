import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/clothing_repository.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    _updateConnectionStatus(connectivityResult);

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (mounted) {
        _updateConnectionStatus(result);
      }
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: Consumer<ClothingRepository>(
        builder: (context, repo, child) {
final user = repo.remoteDataSource.currentUser;
          final isSignedIn = repo.isSignedIn;

          if (!isSignedIn) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, size: 100, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "Sign in to sync your gear with Google Drive",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isOnline ? () => repo.signIn() : null,
                    icon: const Icon(Icons.login),
                    label: const Text("Sign In with Google"),
                  ),
                  if (!_isOnline)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text("No internet connection", style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.black,
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? "User",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? "",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Save to Drive'),
                subtitle: const Text('Backup local data to Google Drive'),
                onTap: _isOnline
                    ? () async {
                        final confirm = await _showConfirmationDialog(
                          context,
                          "Save to Drive",
                          "Are you sure you want to overwrite the cloud data with your local data? This action cannot be undone.",
                        );
                        if (confirm) {
                          await repo.saveToCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saving to Drive...'),
                              ),
                            );
                          }
                        }
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: const Text('Load from Drive'),
                subtitle: const Text('Restore data from Google Drive'),
                onTap: _isOnline
                    ? () async {
                        final confirm = await _showConfirmationDialog(
                          context,
                          "Load from Drive",
                          "Are you sure you want to load data from the cloud? This will merge with your local data.",
                        );
                        if (confirm) {
                          await repo.loadFromCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loading from Drive...'),
                              ),
                            );
                          }
                        }
                      }
                    : null,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () {
                  repo.signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
