import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/connect_pages/choose_sc_page.dart';
import 'package:P2pChords/song_select_pipeline/GroupOverviewPage.dart';
import 'package:P2pChords/display_groups/manageGroupPage.dart';
import 'state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GlobalMode()),
        ChangeNotifierProvider(create: (context) => GlobalUserIds()),
        ChangeNotifierProvider(create: (context) => GlobalName()),
        ChangeNotifierProvider(create: (context) => SectionProvider()),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[300]!, Colors.purple[300]!],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'P2P Test App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GroupOverviewpage()),
                        );
                      },
                      child: Text('Songs spielen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple[700],
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color:
                                Colors.blue[200] ?? Colors.blue, // Border color
                            width: 1, // Border width
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ManageGroupPage()),
                        );
                      },
                      child: Text('Bearbeiten der Gruppen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        foregroundColor: Colors.blue[700],
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color:
                                Colors.blue[200] ?? Colors.blue, // Border color
                            width: 1, // Border width
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              Consumer<GlobalMode>(builder: (context, globalMode, child) {
                return Positioned(
                    top: 20,
                    right: 20,
                    child: ElevatedButton(
                      child: Row(children: [
                        const Icon(Icons.settings),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(globalMode.userState.name.toString()),
                      ]),
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChooseSCStatePage()),
                        )
                      },
                    ));
              }),
            ],
          ),
        ),
      ),
    );
  }
}
