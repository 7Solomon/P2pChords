import 'dart:io';

import 'package:P2pChords/UiSettings/page.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/song_select_pipeline/beamer.dart';
import 'package:P2pChords/styling/Button.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/song.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/networking/Pages/choose_page.dart';
import 'package:P2pChords/song_select_pipeline/groups.dart';
import 'package:P2pChords/groupManagement/Pages/groups.dart';

import 'package:P2pChords/dataManagment/local_manager/config_system_stub.dart'
    if (dart.library.io) 'package:P2pChords/dataManagment/local_manager/config_system.dart';

Widget buildConnectionStatusChip(
    BuildContext context, ConnectionProvider provider) {
  Color chipColor;
  String statusText;

  switch (provider.userState) {
    case UserState.server:
      chipColor = Colors.green;
      statusText = "Server";
      break;
    case UserState.client:
      chipColor = Colors.orange;
      statusText = "Client";
      break;
    default:
      chipColor = Colors.grey;
      statusText = "Offline";
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChooseSCStatePage()),
      );
    },
    child: Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.circle, color: chipColor, size: 14),
      ),
      label: Text(statusText),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 2,
    ),
  );
}

Widget buildMainContent(
    BuildContext context,
    ConnectionProvider songSyncProvider,
    CurrentSelectionProvider currentSection,
    DataLoadeProvider dataLoader) {
  final isClient = songSyncProvider.userState == UserState.client;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo or app icon could go here
          Icon(
            Icons.music_note,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          // App title
          Text(
            'P2P Chords',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 48),

          // Main action button - different for client and server
          AppButton(
            text: isClient ? 'Folge den Lider' : 'Spiele Lieder',
            icon: isClient ? Icons.queue_music : Icons.library_music,
            onPressed: () async {
              if (isClient) {
                if (Platform.isWindows || Platform.isLinux) {
                  bool beamer = await _handleBeamer(context) ?? false;
                  if (beamer) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BeamerPage()),
                    );
                  } else {
                    _handleClientSongAction(
                        context, songSyncProvider, currentSection, dataLoader);
                  }
                } else {
                  _handleClientSongAction(
                      context, songSyncProvider, currentSection, dataLoader);
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GroupOverviewpage()),
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Manage groups button
          AppButton(
            text: 'Gruppen verwalten',
            icon: Icons.group,
            type: AppButtonType.secondary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageGroupPage()),
              );
            },
          ),

          const SizedBox(height: 20),

          // Ui  Stuff
          AppButton(
            text: 'UI Einstellungen',
            icon: Icons.palette,
            type: AppButtonType.secondary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UisettingsPage()),
              );
            },
          ),
          const SizedBox(height: 20),

          // Local widget for additional features
          buildLocalWidget(context),

          const Spacer(),

          // Connection status indicator at the bottom
          if (songSyncProvider.connectedDeviceIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '${songSyncProvider.connectedDeviceIds.length} device(s) connected',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget buildLocalWidget(BuildContext context) {
  final privateFeatures = PrivateFeatures();
  if (privateFeatures.hasHalfLegalStuff) {
    return privateFeatures.buildHalfLegalWidget(context);
  }

  return const SizedBox.shrink();
}

Future<bool?> _handleBeamer(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Beamer Option'),
        content: const Text(
            'Du bist auf einem PC: Willst du eine Beamer Display, oder die Normale Seitenansicht?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Normale ansicht'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Beamer ansicht'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}

void _handleClientSongAction(
    BuildContext context,
    ConnectionProvider songSyncProvider,
    CurrentSelectionProvider currentSection,
    DataLoadeProvider dataLoader) {
  if (songSyncProvider.connectedDeviceIds.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChordSheetPage()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You are not connected to a server yet'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
      ),
    );
  }
}
