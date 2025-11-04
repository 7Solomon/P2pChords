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
  String? _expandedGroupName;

  @override
  void initState() {
    super.initState();
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
      ConnectionProvider connectionProvider, SongData songData) async {
    if (connectionProvider.userRole == UserRole.hub) {
      //bool? shouldSend = await showShouldSendDialog();
      //if (shouldSend == true) {
        await connectionProvider.sendSongDataToAll(songData);
        //SnackService().showSuccess('Daten wurden gesendet');
      //}
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Gruppen'),
      ),
      resizeToAvoidBottomInset: false, 
      floatingActionButton: buildFloatingActionButtonForGroups(context),
      body: Consumer<DataLoadeProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (dataProvider.groups.isEmpty) {
            return const Center(child: Text('Keine Gruppen vorhanden'));
          }

          final groupNames = dataProvider.groups.keys.toList();

          return ReorderableListView.builder(
            itemCount: groupNames.length,
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              await dataProvider.reorderGroups(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              String groupName = groupNames[index];
              SongData songData = dataProvider.getSongData(groupName);
              int songCount = dataProvider.groups[groupName]?.length ?? 0;
              final isExpanded = _expandedGroupName == groupName;

              return CExpandableListTile(
                key: ValueKey(groupName),
                uniqueKey: groupName,
                title: groupName,
                subtitle: '$songCount Song${songCount != 1 ? 's' : ''}',
                icon: Icons.folder,
                isExpanded: isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedGroupName = expanded ? groupName : null;
                  });
                },
                dragHandleBuilder: (context) {
                  return ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  );
                },
                onTap: () async {
                  if (isExpanded) {
                    setState(() {
                      _expandedGroupName = null;
                    });
                    return;
                  }

                  Provider.of<CurrentSelectionProvider>(context, listen: false)
                      .setCurrentGroup(groupName);
                  if (connectionProvider.userRole != UserRole.spoke) {
                    if (connectionProvider.userRole == UserRole.hub) {
                      await sendSongDataToAllClients(
                          connectionProvider, songData);
                    }
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Songoverviewpage(),
                        ),
                      );
                    }
                  } else {
                    SnackService().showWarning(
                        'Du kannst keine Gruppen auswählen, wenn du ein Client bist');
                  }
                },
                actions: [
                  CExpandableAction(
                    icon: Icons.download,
                    tooltip: 'Exportieren',
                    onPressed: () async {
                      await exportGroupsData(songData);
                    },
                  ),
                  CExpandableAction(
                    icon: Icons.delete,
                    tooltip: 'Löschen',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    onPressed: () async {
                      final confirmed = await CDissmissible
                          .showDeleteConfirmationDialog(context);
                      if (confirmed == true) {
                        await dataProvider.removeGroup(groupName);
                        if (_expandedGroupName == groupName) {
                          setState(() {
                            _expandedGroupName = null;
                          });
                        }
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
