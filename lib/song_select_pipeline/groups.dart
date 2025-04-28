import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/groupManagement/floating_buttons.dart';
import 'package:P2pChords/groupManagement/functions.dart';
import 'package:P2pChords/song_select_pipeline/group.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:P2pChords/styling/Tiles.dart';

class GroupOverviewpage extends StatefulWidget {
  const GroupOverviewpage({Key? key}) : super(key: key);

  @override
  _GroupOverviewpageState createState() => _GroupOverviewpageState();
}

class _GroupOverviewpageState extends State<GroupOverviewpage> {
  late DataLoadeProvider _dataProvider;
  late CurrentSelectionProvider _currentSelectionProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataLoadeProvider>(context, listen: false);
    _currentSelectionProvider =
        Provider.of<CurrentSelectionProvider>(context, listen: false);
  }

  Future<bool?> showShouldSendDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Senden der Gruppen Daten'),
          content: const Text('Willst du die Datein zu den clients Senden?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User pressed No
              },
              child: const Text('Nein'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User pressed Yes
              },
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendSongDataToAllClients(
      connectionProvider, SongData songData) async {
    if (connectionProvider.userState == UserState.server) {
      bool? shouldSend = await showShouldSendDialog();

      // If Yes, send data
      if (shouldSend == true) {
        bool success = await connectionProvider.dataSyncService
            .sendSongDataToAllClients(songData);

        if (success) {
          SnackService()
              .showSuccess('Daten erfolgreich an alle Clients gesendet');
        } else {
          SnackService().showError('Fehler beim Senden der Daten');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Gruppen'),
        //actions: [
        //  IconButton(
        //    icon: const Icon(Icons.refresh),
        //    onPressed: _dataProvider.refreshData,
        //  ),
        //],
      ),
      floatingActionButton: buildFloatingActionButtonForGroups(context),
      body: _dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataProvider.groups.isEmpty
              ? const Center(child: Text('Keine Gruppen vorhanden'))
              : ListView.builder(
                  itemCount: _dataProvider.groups.length,
                  itemBuilder: (context, index) {
                    String groupName =
                        _dataProvider.groups.keys.elementAt(index);
                    SongData songData = _dataProvider.getSongData(groupName);

                    return CDissmissible.deleteAndAction(
                      key: Key(groupName),
                      deleteIcon: Icons.delete,
                      actionIcon: Icons.download,
                      deleteConfirmation: () =>
                          CDissmissible.showDeleteConfirmationDialog(context),
                      confirmActionDismiss: () async {
                        await exportGroupsData(songData);
                      },
                      confirmDeleteDismiss: () async {
                        await _dataProvider.removeGroup(groupName);
                        setState(() {});
                      },
                      child: CListTile(
                        title: groupName,
                        context: context,
                        subtitle: 'Klicke um die Songs der Gruppe anzusehen',
                        icon: Icons.file_copy,
                        onTap: () async {
                          _currentSelectionProvider.setCurrentGroup(groupName);
                          if (connectionProvider.userState !=
                              UserState.client) {
                            if (connectionProvider.userState ==
                                UserState.server) {
                              await sendSongDataToAllClients(
                                  connectionProvider, songData);
                            }
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const Songoverviewpage(),
                                ),
                              );
                            }
                          } else {
                            SnackService().showWarning(
                                'Du kannst keine Gruppen auswählen, wenn du ein Client bist');
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
