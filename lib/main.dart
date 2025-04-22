import 'package:P2pChords/dataManagment/provider/app_ui_provider.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/provider/sheet_ui_provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/mainPage/page.dart';
import 'package:P2pChords/navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Completely clear and reset SharedPreferences in case of corruption
  try {
    debugPrint('Initializing SharedPreferences...');
    await MultiJsonStorage.initialize();
  } catch (e) {
    debugPrint('Critical error during initialization: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataLoadeProvider()),
        ChangeNotifierProvider(create: (_) => CurrentSelectionProvider()),
        ChangeNotifierProvider(
            create: (context) => ConnectionProvider(
                  dataLoader:
                      Provider.of<DataLoadeProvider>(context, listen: false),
                  currentSelectionProvider:
                      Provider.of<CurrentSelectionProvider>(context,
                          listen: false),
                )),
        ChangeNotifierProvider(create: (_) => SheetUiProvider()),
        ChangeNotifierProvider(create: (_) => AppUiProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppUiProvider>(
      builder: (context, appUiProvider, _) {
        return MaterialApp(
          title: 'P2P Chords',
          theme: appUiProvider.currentTheme,
          home: const MainPage(),
          navigatorKey: NavigationService.navigatorKey,
        );
      },
    );
  }
}
