import 'package:P2pChords/connect/connectionLogic/dataSendLogic.dart';
import 'package:P2pChords/customeWidgets/MetronomeBlinkWidget.dart';
import 'package:P2pChords/metronome/MetronomePage.dart';
import 'package:P2pChords/metronome/test.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/connect/pages/choosePage.dart';
import 'package:P2pChords/song_select_pipeline/GroupOverviewPage.dart';
import 'package:P2pChords/groupManagement/manageGroupPage.dart';
import 'package:P2pChords/uiSettings.dart';
import 'state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NearbyMusicSyncProvider()),
        BlocProvider<MetronomeBloc>(
          create: (context) {
            final syncProvider =
                Provider.of<NearbyMusicSyncProvider>(context, listen: false);
            final bloc = MetronomeBloc(
              onMetronomeChanged: syncProvider.sendMetronomeUpdate,
            );
            syncProvider.onMetronomeUpdateReceived =
                (bpm, isPlaying, tickCount) {
              bloc.add(SyncMetronome(bpm, isPlaying, tickCount));
            };
            return bloc;
          },
        ),
        ChangeNotifierProvider(create: (_) => UiSettings()),
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
    final globalSongData = Provider.of<UiSettings>(context, listen: true);
    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: true);
    //songSyncProvider.updateDisplaySnack(); muss gemounted sein
    //globalSongData.getListOfDisplaySections(2);
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
              BlinkingCircle(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'P2P Test App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Conditionally render "Songs spielen" or "Folge den Songs" button
                    songSyncProvider.userState != UserState.client
                        ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const GroupOverviewpage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.purple[700],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: Colors.blue[200] ??
                                      Colors.blue, // Border color
                                  width: 1, // Border width
                                ),
                              ),
                            ),
                            child: const Text('Songs spielen'),
                          )
                        :
                        // If user is a client
                        ElevatedButton(
                            onPressed: () async {
                              // Send data to the server when the user is a client
                              if (songSyncProvider
                                  .connectedDeviceIds.isNotEmpty) {
                                if (globalSongData.currentGroup
                                    .contains(globalSongData.currentSongHash)) {
                                  // Navigate to the ChordSheetPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ChordSheetPage()),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Do bist noch nicht mit einem Server verbunden')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  const Color.fromARGB(255, 196, 111, 233),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: Colors.blue[200] ??
                                      Colors.blue, // Border color
                                  width: 1, // Border width
                                ),
                              ),
                            ),
                            child: const Text('Folge den Songs'),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
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
                      child: const Text('Bearbeiten der Gruppen'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MetronomePage(),
                            ),
                          );
                        },
                        child: const Text('Metronome')),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: ElevatedButton(
                  child: Row(
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 10),
                      Text(songSyncProvider.userState.name.toString()),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChooseSCStatePage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
