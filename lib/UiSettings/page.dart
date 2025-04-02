import 'package:P2pChords/UiSettings/songWithControlls.dart';
import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/state.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UisettingsPage extends StatefulWidget {
  const UisettingsPage({super.key});

  @override
  _UisettingsPageState createState() => _UisettingsPageState();
}

class _UisettingsPageState extends State<UisettingsPage> {
  double _currentFontSize = 16.0;
  void displaySnack(String str) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChordUtils.initialize(context);
      _initializeCurrentSelection();
    });
  }

  void _initializeCurrentSelection() {
    final dataLoader = Provider.of<DataLoadeProvider>(context, listen: false);
    final currentSelection =
        Provider.of<CurrentSelectionProvider>(context, listen: false);

    if (dataLoader.songs != null && dataLoader.songs!.isNotEmpty) {
      currentSelection.setCurrentGroup('default');
      currentSelection.setCurrentSectionIndex(0);
      currentSelection.setCurrentSong(dataLoader.songs!.keys.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<CurrentSelectionProvider, DataLoadeProvider, UIProvider,
        ConnectionProvider>(
      builder: (context, currentSelection, dataLoader, uiProvider,
          connectionProvider, _) {
        if (dataLoader.songs == null || dataLoader.songs!.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Keine Lieder vorhanden'),
            ),
          );
        }

        if (currentSelection.currentSongHash == null) {
          if (dataLoader.songs!.isNotEmpty) {
            // Using a post-frame callback to avoid modifying state during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              currentSelection.setCurrentGroup('default');
              currentSelection.setCurrentSectionIndex(0);
              currentSelection.setCurrentSong(dataLoader.songs!.keys.first);
            });
          }

          // Show loading indicator while waiting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return PopScope(
          canPop: _currentFontSize == (uiProvider.fontSize ?? 16.0),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_currentFontSize != (uiProvider.fontSize ?? 16.0)) {
              final bool? shouldSave = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ungespeicherte Änderungen'),
                  content: const Text(
                      'Willst du die geänderten Einstellungen Speichern?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Verwerfen'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Speichern'),
                    ),
                  ],
                ),
              );

              // If user confirmed save
              if (shouldSave == true) {
                uiProvider.setFontSize(_currentFontSize);
                displaySnack('Einstellungen gespeichert');
              }

              // Now we can safely pop
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text("UI Einstellungen"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  // Same logic as in PopScope
                  if (_currentFontSize == (uiProvider.fontSize ?? 16.0)) {
                    // No changes, safe to pop
                    Navigator.of(context).pop();
                  } else {
                    // Show confirmation dialog
                    final bool? shouldSave = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ungespeicherte Änderungen'),
                        content: const Text(
                            'Willst du die geänderten Einstellungen Speichern?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Verwerfen'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Speichern'),
                          ),
                        ],
                      ),
                    );

                    // Handle the result
                    if (shouldSave == true) {
                      uiProvider.setFontSize(_currentFontSize);
                      displaySnack('Einstellungen gespeichert');
                    }

                    // Now we can safely pop
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    uiProvider.setFontSize(_currentFontSize);
                    displaySnack('Einstellungen gespeichert');
                  },
                ),
              ],
            ),
            body: SongSheetWithControls(
              songs: dataLoader.getSongsInGroup(currentSelection.currentGroup!),
              songIndex: dataLoader.getSongIndex(currentSelection.currentGroup!,
                  currentSelection.currentSongHash!),
              sectionIndex: currentSelection.currentSectionIndex!,
              currentKey: uiProvider.currentKey ?? 'C',
              startFontSize: uiProvider.fontSize ?? 16.0,
              startSectionCount: uiProvider.sectionCount ?? 2,
              onSectionChanged: (index) {
                currentSelection.setCurrentSectionIndex(index);
              },
              onSongChanged: (index) {
                String hash = dataLoader.getHashByIndex(
                    currentSelection.currentGroup!, index);
                currentSelection.setCurrentSong(hash);
              },
              onFontSizeChanged: (fontSize) {
                _currentFontSize = fontSize;
              },
            ),
          ),
        );
      },
    );
  }
}
