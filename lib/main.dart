import 'package:P2pChords/customeWidgets/Themes.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/mainPage/page.dart';
import 'package:P2pChords/navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NearbyMusicSyncProvider()),
        ChangeNotifierProvider(create: (_) => DataLoadeProvider()),
        ChangeNotifierProvider(create: (_) => CurrentSelectionProvider()),
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
