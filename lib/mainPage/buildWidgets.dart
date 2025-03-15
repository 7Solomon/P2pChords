import 'package:P2pChords/UiSettings/page.dart';
import 'package:P2pChords/customeWidgets/ButtonWidget.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/ChordSheetPage.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/utils/test.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/networking/Pages/choosePage.dart';
import 'package:P2pChords/song_select_pipeline/GroupOverviewPage.dart';
import 'package:P2pChords/groupManagement/Pages/manageGroupPage.dart';

Widget buildConnectionStatusChip(
    BuildContext context, NearbyMusicSyncProvider provider) {
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
      statusText = "Disconnected";
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
    NearbyMusicSyncProvider songSyncProvider,
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
            onPressed: () {
              if (isClient) {
                _handleClientSongAction(
                    context, songSyncProvider, currentSection, dataLoader);
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

void _handleClientSongAction(
    BuildContext context,
    NearbyMusicSyncProvider songSyncProvider,
    CurrentSelectionProvider currentSection,
    DataLoadeProvider dataLoader) {
  if (songSyncProvider.connectedDeviceIds.isNotEmpty) {
    if (dataLoader.groups != null &&
        dataLoader.groups!.keys.contains(currentSection.currentGroup)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChordSheetPage()),
      );
    }
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
