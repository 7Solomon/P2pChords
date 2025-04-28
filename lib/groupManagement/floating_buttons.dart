import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
import 'package:P2pChords/dataManagment/Pages/load_json_page.dart';
import 'package:P2pChords/dataManagment/data_base/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/groupManagement/Pages/songs.dart';
import 'package:P2pChords/groupManagement/functions.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

Widget buildFloatingActionButtonForGroups(BuildContext context) {
  return HierarchicalSpeedDial(
    theme: Theme.of(context),
    categories: [
      SpeedDialCategory(
        title: 'Gruppen',
        icon: Icons.add_circle,
        color: Colors.blue,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.group_add),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Neue Gruppe',
            onTap: () => createNewGroupDialog(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.download),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Gruppe importieren',
            onTap: () => importGroup(),
          ),
        ],
      ),
      SpeedDialCategory(
        title: 'Songs',
        icon: Icons.add_circle,
        color: Colors.orange,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Song erstellen',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongEditPage(
                    song: Song.empty(),
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.download),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Song Importieren',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JsonFilePickerPage(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.download),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Songs aus einem Server importieren',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServerImportPage(),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}

Widget buildFloatingActionButtonForGroup(BuildContext context, String? group) {
  return CSpeedDial(
    theme: Theme.of(context),
    children: [
      SpeedDialChild(
          child: const Icon(Icons.group_add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: 'Songs zur Gruppe hinzufügen',
          onTap: () {
            if (group == null) {
              SnackService().showError(
                'Ein Fehler ist passiert, Bitte erst eine Gruppe auswählen!',
              );
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllSongsPage(
                  group: group!,
                ),
              ),
            );
          }),
    ],
  );
}
