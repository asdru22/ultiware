import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/gear_library_screen.dart';

import 'package:provider/provider.dart';
import 'data/clothing_repository.dart';
import 'data/datasources/google_drive_data_source.dart';
import 'data/datasources/local_data_source.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final googleDriveDataSource = GoogleDriveDataSource();
  final localDataSource = LocalDataSource();
  final clothingRepository = ClothingRepository(googleDriveDataSource, localDataSource);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: clothingRepository)],
      child: const UltimateFrisbeeGearApp(),
    ),
  );
}

class UltimateFrisbeeGearApp extends StatelessWidget {
  const UltimateFrisbeeGearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultiware',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const GearLibraryScreen(),
    );
  }
}
