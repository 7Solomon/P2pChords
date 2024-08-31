import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/connect_pages/choose_sc_page.dart';

import 'state.dart';
import 'display_chords/test.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GlobalMode()),
        ChangeNotifierProvider(create: (context) => GlobalUserIds()),
        ChangeNotifierProvider(create: (context) => GlobalName()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2P Connection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'P2P Test App',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              child: const Text('Beginne bei SC Choose'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChooseSCStatePage()),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              child: const Text('Display Test'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChordSheetPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
