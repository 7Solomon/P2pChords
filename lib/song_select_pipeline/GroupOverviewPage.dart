import 'package:P2pChords/connect/connectionLogic/dataSendLogic.dart';
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
  Map<String, Map<String, dynamic>> _allGroupData = {};
  Map<String, List<Map<String, String>>> _allGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllJsons();
  }

  Future<void> _loadAllJsons() async {
    setState(() => _isLoading = true);
    _allGroups = await MultiJsonStorage.getAllGroups();

    for (MapEntry<String, List<Map<String, String>>> entry
        in _allGroups.entries) {
      String groupName = entry.key;
      List<Map<String, String>> groupValue = entry.value;

      // Initialize the songs list for each group
      for (Map<String, String> songValue in groupValue) {
        String songHash = songValue['hash']!;
        Map<String, dynamic>? songData =
            await MultiJsonStorage.loadJson(songHash);
        _allGroupData[groupName]?[songHash] = songData;
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final nearbyProvider = Provider.of<NearbyMusicSyncProvider>(context);
    //final currentSongData = Provider.of<SongProvider>(context, listen: false);

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
                        /// !!!!!!!!!!!!!!!!!!!!!!!!!!!
                        nearbyProvider.updateGroup(key);
                        // Navigate to the SongOverviewPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Songoverviewpage(
                              onGroupDeleted: _loadAllJsons,
                            ),
                          ),
                        );

                        // Check if the device is a server and send data to clients if it is
                        if (nearbyProvider.userState == UserState.server) {
                          Map<String, dynamic> songData =
                              _allGroupData[key] ?? {};

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
                                key, songData);

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
                      },
                    );
                  },
                ),
    );
  }
}
