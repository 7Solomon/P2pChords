import 'dart:io';

import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/networking/pages/connection_management.dart';
import 'package:P2pChords/song_select_pipeline/beamer.dart';
import 'package:P2pChords/styling/Button.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/song.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/song_select_pipeline/groups.dart';

import 'package:P2pChords/dataManagment/local_manager/config_system.dart';
import 'package:window_manager/window_manager.dart';
Widget buildConnectionStatusChip(
    BuildContext context, ConnectionProvider provider) {
  Color chipColor;
  String statusText;
  IconData iconData;

  if (provider.isHub) {
    chipColor = Colors.green;
    statusText = "Hub (${provider.connectedSpokeCount})";
    iconData = Icons.router;
  } else if (provider.isSpoke) {
    chipColor = Colors.blue;
    statusText = provider.isConnectedToHub ? "Verbunden" : "Verbinde...";
    iconData = Icons.smartphone;
  } else {
    chipColor = Colors.grey;
    statusText = "Offline";
    iconData = Icons.cloud_off;
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConnectionManagementPage(),
        ),
      );
    },
    child: Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(iconData, color: chipColor, size: 16),
      ),
      label: Text(
        statusText,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}
Widget buildMainContent(
    BuildContext context,
    ConnectionProvider connectionProvider,
    CurrentSelectionProvider currentSection,
    DataLoadeProvider dataLoader) {
  final isClient = connectionProvider.userRole == UserRole.spoke;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600), // Limit max width
        child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo or app icon could go here
            Center(
              child: Icon(
                Icons.music_note,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // App title
            Center(
              child: Text(
              'P2P Chords',
              style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 48),

            // Main action button - different for client and server
            AppButton(
              text: isClient ? 'Folge den Songs' : 'Songs',
              icon: isClient ? Icons.queue_music : Icons.library_music,
              onPressed: () async {
                if (isClient) {
                  connectionProvider.requestSongDataFromHub();
                  bool beamer = await _handleBeamer(context) ?? false;
                  if (beamer) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BeamerPage()),
                    );
                  } else {
                    _handleClientSongAction(
                        context, connectionProvider, currentSection, dataLoader);
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

            // Local widget for additional features
            buildLocalWidget(context),

            const SizedBox(height: 20),

            // Manage groups button
            buildCloseButton(context),

          ],
        ),
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
            'Du bist auf ein Client: Willst du eine Beamer Display, oder die Normale Seitenansicht?'),
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


Widget buildCloseButton(BuildContext context) {
  return SizedBox(
    width: 80, // Fixed small width
    child: ElevatedButton(
            onPressed: () => _showExitConfirmation(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        elevation: 2,
        
      ),
      child: Icon(Icons.close, size: 24, color: Colors.red.shade700),
    ),
  );
}

Future<void> _showExitConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('App beenden'),
        content: const Text('Möchtest du P2P Chords wirklich verlassen?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Abbrechen'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: const Text('Wirklich Verlassen'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    await windowManager.close();
    exit(0);
  }
}



void _handleClientSongAction(
    BuildContext context,
    ConnectionProvider connectionProvider,
    CurrentSelectionProvider currentSection,
    DataLoadeProvider dataLoader) {
      if (connectionProvider.isConnectedToHub) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChordSheetPage()),
        );
      } else {
        SnackService().showInfo(
          'Du bist noch nicht mit einem Server verbunden',
        );
      }
}

Future<void> toggleFullScreen() async {
  bool isFullScreen = await windowManager.isFullScreen();
  await windowManager.setFullScreen(!isFullScreen);
}