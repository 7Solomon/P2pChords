import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/provider/beamer_ui_provider.dart';
import 'package:P2pChords/utils/notification_service.dart'; // Assuming you have this
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BeamerSettingsPage extends StatefulWidget {
  const BeamerSettingsPage({super.key});

  @override
  _BeamerSettingsPageState createState() => _BeamerSettingsPageState();
}

class _BeamerSettingsPageState extends State<BeamerSettingsPage> {
  late BeamerUiVariables _tempUiVariables;
  bool _hasUnsavedChanges = false;
  bool _initialized = false;

  // List of available font families
  final List<String> _fontFamilies = [
    'Courier New',
    'Roboto',
    'Lato',
    'Montserrat',
    'Arial',
    'Times New Roman'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final beamerUiProvider = Provider.of<BeamerUiProvider>(context);
      _tempUiVariables = beamerUiProvider.uiVariables.copyWith();
      _initialized = true;
    }
  }

  void _showSnackbar(String message) {
    SnackService().showInfo(message); // Use your notification service
  }

  Future<bool?> _showSaveDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
            'Möchtest du die geänderten Beamer-Einstellungen speichern?'),
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
    final beamerUiProvider =
        Provider.of<BeamerUiProvider>(context, listen: false);
    beamerUiProvider.setUiVariables(_tempUiVariables);
    beamerUiProvider.saveToPrefs();
    setState(() {
      _hasUnsavedChanges = false;
    });
    _showSnackbar('Beamer-Einstellungen gespeichert');
  }

  Future<void> _handleBackNavigation() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final bool? shouldSave = await _showSaveDialog();
    if (shouldSave == true) {
      _saveSettings(); // Save happens within this method now
    } else {
      // If discarding, reset temp variables (optional, depends on desired behavior)
      // final beamerUiProvider = Provider.of<BeamerUiProvider>(context, listen: false);
      // _tempUiVariables = beamerUiProvider.uiVariables.copyWith();
      // _hasUnsavedChanges = false;
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _checkForChanges() {
    final beamerUiProvider =
        Provider.of<BeamerUiProvider>(context, listen: false);
    setState(() {
      _hasUnsavedChanges =
          _tempUiVariables.isDifferent(beamerUiProvider.uiVariables);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the provider but don't listen here for rebuilds on settings change
    // We manage changes via _tempUiVariables and setState
    final beamerUiProvider =
        Provider.of<BeamerUiProvider>(context, listen: false);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200], // Lighter background for settings
        appBar: AppBar(
          title: const Text("Beamer UI Einstellungen"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              // Disable save button if no changes
              onPressed: _hasUnsavedChanges ? _saveSettings : null,
              tooltip: 'Einstellungen speichern',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            // Use ListView for potentially more settings later
            children: [
              // --- Font Size Setting ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schriftgröße',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: _tempUiVariables.fontSize,
                        min: 10.0,
                        max: 100.0,
                        divisions: 30,
                        label: _tempUiVariables.fontSize.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _tempUiVariables.fontSize = value;
                            _checkForChanges();
                          });
                        },
                      ),
                      Center(
                          child: Text(
                              'Aktuell: ${_tempUiVariables.fontSize.toStringAsFixed(1)}')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Font Family Setting ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schriftart',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      DropdownButton<String>(
                        value: _tempUiVariables.fontFamily,
                        isExpanded: true,
                        items: _fontFamilies.map((String family) {
                          return DropdownMenuItem<String>(
                            value: family,
                            child: Text(family,
                                style: TextStyle(fontFamily: family)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _tempUiVariables.fontFamily = newValue;
                              _checkForChanges();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Preview Section ---
              Text(
                'Vorschau:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.black, // Match Beamer background
                child: Center(
                  child: Text(
                    'Beispieltext für Vorschau\nZeile 2 mit mehr Text',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _tempUiVariables.fontFamily,
                      fontSize: _tempUiVariables.fontSize,
                      color: Colors.white,
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
