import 'package:P2pChords/UiSettings/data_class.dart';
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
  late UiVariables _uiVariables;

  late Future<bool> _initFuture;
  bool _hasUnsavedChanges = false;
  bool _initialized = false;

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
    sheetUiProvider.setUiVariables(_uiVariables);
    _hasUnsavedChanges = false;
    sheetUiProvider.saveToPrefs();
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
    final bool uiVariablesChanged = _uiVariables.isDifferent(
      sheetUiProvider.uiVariables,
    );
    setState(() {
      _hasUnsavedChanges = uiVariablesChanged;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final sheetUiProvider = Provider.of<SheetUiProvider>(context);
      _uiVariables = sheetUiProvider.uiVariables;
      _initialized = true;
    }
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
                  currentKey: sheetUiProvider.currentKey,
                  uiVariables: sheetUiProvider.uiVariables,
                  onSectionChanged: (index) {
                    currentSelection.setCurrentSectionIndex(index);
                  },
                  onSongChanged: (index) {
                    String? hash = dataLoader.getHashByIndex(
                        currentSelection.currentGroup!, index);
                    if (hash == null) {
                      return;
                    }
                    currentSelection.setCurrentSong(hash);
                  },
                  onUiVariablesChanged: (newUiVariables) {
                    setState(() {
                      _uiVariables = newUiVariables;
                      _checkForChanges(sheetUiProvider);
                    });
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
