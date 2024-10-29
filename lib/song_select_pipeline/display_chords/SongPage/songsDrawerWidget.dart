import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/SongPage.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/drawerWidget.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongListDrawer extends StatelessWidget {
  SongListDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final songSyncProvider =
        Provider.of<NearbyMusicSyncProvider>(context, listen: false);
    //print(currentSongprovider.currentGroup);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              songSyncProvider.currentGroup,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          // Use FutureBuilder to handle the async operation
          FutureBuilder(
            future: MultiJsonStorage.loadJsonsFromGroup(songSyncProvider
                .currentGroup), // Fetch the songs asynchronously
            builder: (context, snapshot) {
              // Check for data and loading states
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator()); // Show a loading indicator while waiting
              } else if (snapshot.hasError) {
                return Center(
                    child:
                        Text('Error: ${snapshot.error}')); // Handle error state
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child:
                        Text('No songs available')); // Handle empty data state
              }
              final Map<String, Map<String, dynamic>> songsData =
                  snapshot.data!;

              return ListView.builder(
                shrinkWrap:
                    true, // Ensure it takes only as much space as needed
                physics:
                    NeverScrollableScrollPhysics(), // Prevent scrolling issues
                itemCount: songsData.length,
                itemBuilder: (context, index) {
                  final hash = songsData.keys.elementAt(index);
                  final song = songsData[hash]!;
                  final name = song['header']['name'] ?? 'noName';

                  return ListTile(
                    title: Text(name),
                    onTap: () async {
                      songSyncProvider.updateSongAndSection(hash, [0, 1], 2);
                      // Close the drawer
                      Navigator.of(context).pop();

                      // Reload the ChordSheetPage
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ChordSheetPage(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
