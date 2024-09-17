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
    final globalMode = Provider.of<GlobalMode>(context, listen: false);
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
                        if (globalMode.userState == UserState.server) {
                          final songData = _allGroupData[key]!;
                          bool success =
                              await nearbyProvider.sendGroupData(key, songData);
                          // Display Sucessi If you want but I dont want to implement my boi
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Info über status'),
                              action: SnackBarAction(
                                label: 'mehr..',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Detail Infos'),
                                        content: SingleChildScrollView(
                                          child: success
                                              ? const Text(
                                                  'Die Daten wurden erfolgreich an die Clients gesendet')
                                              : const Text(
                                                  'Die Daten konnten nicht an die Clients gesendet werden'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                            child: const Text('Schließen'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
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
