import 'package:P2pChords/connect/connectionLogic/dataSendLogic.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../dataManagment/storageManager.dart';
import '../dataManagment/Pages/saveJsonPage.dart';
import 'SongOverviewPage.dart';
import '../state.dart'; // Import the file containing GlobalMode

import 'package:P2pChords/customeWidgets/TileWidget.dart';

class GroupOverviewpage extends StatefulWidget {
  const GroupOverviewpage({Key? key}) : super(key: key);

  @override
  _GroupOverviewpageState createState() => _GroupOverviewpageState();
}

class _GroupOverviewpageState extends State<GroupOverviewpage> {
  Map<String, Map<String, Map>> _allGroupData = {};
  Map<String, List<Map<String, String>>> _allGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllJsons();
  }

  Future<void> _loadAllJsons() async {
    //print('Loading all JSONs');

    setState(() => _isLoading = true);
    _allGroups = await MultiJsonStorage.getAllGroups();

    for (MapEntry<String, List<Map<String, String>>> entry
        in _allGroups.entries) {
      String groupName = entry.key;
      List<Map<String, String>> groupValue = entry.value;
      _allGroupData[groupName] = {};

      // Initialize the songs list for each group
      for (Map<String, String> songValue in groupValue) {
        String songHash = songValue['hash']!;

        Map<String, dynamic>? songData =
            await MultiJsonStorage.loadJson(songHash);
        if (songData != null) {
          _allGroupData[groupName]![songHash] = songData;
        }
      }
    }
    setState(() => _isLoading = false);
  }

  //void test(){
  //  FutureBuilder(
  //            future: MultiJsonStorage.loadJsonsFromGroup(
  //                songSyncProvider.currentGroup),
  //            builder: (context, snapshot) {
  //              if (snapshot.connectionState == ConnectionState.waiting) {
  //                return const Center(child: CircularProgressIndicator());
  //              } else if (snapshot.hasError) {
  //                return Center(child: Text('Error: ${snapshot.error}'));
  //              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //                return const Center(child: Text('No songs available'));
  //              }
  //              // Extract the data from snapshot
  //              final Map<String, Map<String, dynamic>> songsData =
  //                  snapshot.data!;
  //              //
  //}

  @override
  Widget build(BuildContext context) {
    final nearbyProvider = Provider.of<NearbyMusicSyncProvider>(context);
    final globalData = Provider.of<UiSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Gruppen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllJsons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allGroups.isEmpty
              ? const Center(child: Text('No saved JSONs'))
              : ListView.builder(
                  itemCount: _allGroups.length,
                  itemBuilder: (context, index) {
                    String key = _allGroups.keys.elementAt(index);
                    return CustomListTile(
                      title: key,
                      subtitle: 'Klicke um die Songs der Gruppe anzusehen',
                      icon: Icons.file_copy,
                      onTap: () async {
                        final Map<String, Map> songsDataMap =
                            _allGroupData[key] ?? {};
                        globalData.setSongsDataMap(songsDataMap);
                        nearbyProvider.sendSongsDataMap(songsDataMap);
                        globalData.setCurrentGroup(key);

                        if (nearbyProvider.userState != UserState.client) {
                          if (nearbyProvider.userState == UserState.server) {
                            bool? shouldSend = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Senden der Gruppen Daten'),
                                  content: const Text(
                                      'Willst du die Datein zu den clients Senden?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(false); // User pressed No
                                      },
                                      child: const Text('Nein'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(true); // User pressed Yes
                                      },
                                      child: const Text('Ja'),
                                    ),
                                  ],
                                );
                              },
                            );

                            // If the user presses Yes, send the data
                            if (shouldSend == true) {
                              bool success = await nearbyProvider.sendGroupData(
                                  key, songsDataMap);

                              // Optionally show a success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: success
                                      ? const Text(
                                          'Daten erfolgreich an alle Clients gesendet')
                                      : const Text(
                                          'Fehler beim Senden der Daten'),
                                ),
                              );
                            }
                          }

                          // Navigate to the SongOverviewPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Songoverviewpage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Du kannst keine Gruppen auswählen, wenn du ein Client bist'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
