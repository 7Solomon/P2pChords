import 'package:P2pChords/styling/Themes.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/mainPage/page.dart';
import 'package:P2pChords/navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';

void main() async {
  // For Network Tools (MDNS)
  //final appDocDirectory = await getApplicationDocumentsDirectory();
  //await configureNetworkTools(appDocDirectory.path, enableDebugging: true);
  // Normal run
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
        ChangeNotifierProvider(create: (_) => UIProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2P Chords',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainPage(),
      navigatorKey: NavigationService.navigatorKey,
    );
  }
}
