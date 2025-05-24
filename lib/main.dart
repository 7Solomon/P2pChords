import 'package:P2pChords/dataManagment/provider/app_ui_provider.dart';
import 'package:P2pChords/dataManagment/provider/beamer_ui_provider.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/provider/sheet_ui_provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/mainPage/page.dart';
import 'package:P2pChords/navigator.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => BeamerUiProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  MyApp({super.key}) {
    SnackService().init(_scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppUiProvider>(
      builder: (context, appUiProvider, _) {
        return MaterialApp(
          title: 'P2P Chords',
          theme: appUiProvider.currentTheme,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          home: const MainPage(),
          navigatorKey: NavigationService.navigatorKey,
        );
      },
    );
  }
}
