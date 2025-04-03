import 'package:P2pChords/UiSettings/songWithControlls.dart';
import 'package:P2pChords/UiSettings/ui_styles.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider.dart';
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
  int _currentSectionCount = 2;
  late Future<bool> _initFuture;
  bool _hasUnsavedChanges = false;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showSaveDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content:
            const Text('Willst du die geänderten Einstellungen speichern?'),
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
  }

  void _saveSettings() {
    final sheetUiProvider =
        Provider.of<SheetUiProvider>(context, listen: false);
    sheetUiProvider.setFontSize(_currentFontSize);
    sheetUiProvider.setSectionCount(_currentSectionCount);
    _hasUnsavedChanges = false;
    _showSnackbar('Einstellungen gespeichert');
  }

  Future<void> _handleBackNavigation() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final bool? shouldSave = await _showSaveDialog();
    if (shouldSave == true) {
      _saveSettings();
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _checkForChanges(SheetUiProvider sheetUiProvider) {
    final bool fontSizeChanged =
        _currentFontSize != (sheetUiProvider.fontSize ?? 16.0);
    final bool sectionCountChanged =
        _currentSectionCount != (sheetUiProvider.sectionCount ?? 2);

    setState(() {
      _hasUnsavedChanges = fontSizeChanged || sectionCountChanged;
    });
  }

  @override
  void initState() {
    super.initState();
    final dataLoader = Provider.of<DataLoadeProvider>(context, listen: false);
    final currentSelection =
        Provider.of<CurrentSelectionProvider>(context, listen: false);

    _initFuture = Future.microtask(() {
      if (mounted) {
        ChordUtils.initialize(context);
      } else {
        return false;
      }

      if (dataLoader.songs != null && dataLoader.songs!.isNotEmpty) {
        String songHash = dataLoader.songs!.values.first.hash;
        String? group = dataLoader.getGroupOfSong(songHash);
        if (group == null) {
          return false;
        }

        currentSelection.setCurrentGroup(group);
        currentSelection.setCurrentSectionIndex(0);
        currentSelection.setCurrentSong(songHash);
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == false) {
          return const Scaffold(
            body: Center(child: Text('Fehler bei der Initialisierung')),
          );
        }

        return Consumer4<CurrentSelectionProvider, DataLoadeProvider,
            SheetUiProvider, ConnectionProvider>(
          builder: (context, currentSelection, dataLoader, sheetUiProvider,
              connectionProvider, _) {
            // Initialize current values from provider
            _currentSectionCount = sheetUiProvider.sectionCount ?? 2;
            _currentFontSize = sheetUiProvider.fontSize ?? 16.0;

            // Error handling for missing data
            if (dataLoader.songs == null || dataLoader.songs!.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Keine Lieder vorhanden')),
              );
            }

            if (currentSelection.currentGroup == null ||
                currentSelection.currentSongHash == null ||
                currentSelection.currentSectionIndex == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return PopScope(
              canPop: !_hasUnsavedChanges,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                _handleBackNavigation();
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("UI Einstellungen"),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _handleBackNavigation,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveSettings,
                    ),
                  ],
                ),
                body: SongSheetWithControls(
                  songs: dataLoader
                      .getSongsInGroup(currentSelection.currentGroup!),
                  songIndex: dataLoader.getSongIndex(
                      currentSelection.currentGroup!,
                      currentSelection.currentSongHash!),
                  sectionIndex: currentSelection.currentSectionIndex!,
                  currentKey: sheetUiProvider.currentKey ?? 'C',
                  startFontSize: sheetUiProvider.fontSize ?? 16.0,
                  startSectionCount: sheetUiProvider.sectionCount ?? 2,
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
                    _checkForChanges(sheetUiProvider);
                  },
                  onSectionCountChanged: (sectionCount) {
                    _currentSectionCount = sectionCount;
                    _checkForChanges(sheetUiProvider);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
