import 'package:P2pChords/connect_pages/dataSendLogic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data_management/save_json_in_storage.dart';
import '../data_management/saveJsonPage.dart';
import 'SongOverviewPage.dart';
import '../state.dart'; // Import the file containing GlobalMode

import 'package:P2pChords/customeWidgets/TileWidget.dart';

class GroupOverviewpage extends StatefulWidget {
  const GroupOverviewpage({Key? key}) : super(key: key);

  @override
  _GroupOverviewpageState createState() => _GroupOverviewpageState();
}

class _GroupOverviewpageState extends State<GroupOverviewpage> {
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
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final globalMode = Provider.of<GlobalMode>(context, listen: false);
    final globalDataManager =
        Provider.of<GlobalUserIds>(context, listen: false);
    final currentSongData = Provider.of<SongProvider>(context, listen: false);

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
                        currentSongData.updateGroup(key);
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
                          final songData = {
                            'type': 'group_data',
                            'content': {
                              'groupName': key,
                              'songs': _allGroups[key],
                            },
                          };

                          Map successi = await sendDataToAllClients(
                              songData, globalDataManager.connectedDeviceIds);
                          // Display Sucessi If you want but I dont want to implement my boi
                        }
                      },
                    );
                  },
                ),
    );
  }
}
