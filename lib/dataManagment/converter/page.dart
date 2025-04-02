import 'package:P2pChords/dataManagment/converter/components.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:flutter/material.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedKey;
  String? _selectedTitle;

  Song? _savedSong;

  void _generate() {
    // Function to handle the button press
    String inputText = _controller.text;
    if (_selectedKey == null || inputText.isEmpty || _selectedTitle == null) {
      // Handle the case where no key is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wähle Bitte eine Tonart!')),
      );
      return;
    }
    Song generatedSong =
        converter.convertTextToSong(inputText, _selectedKey!, _selectedTitle!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song generiert!')),
    );
    setState(() {
      _savedSong = generatedSong;
    });
  }

  void showSaveDialog({
    required BuildContext context,
    required Function(String) onSave,
    String title = 'Song speichern',
    String message = 'Möchtest du diesen Song wirklich speichern?',
  }) {
    final TextEditingController groupController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return uiComponents.createSaveDialog(
          context: dialogContext,
          groupController: groupController,
          onSave: onSave,
          title: title,
          message: message,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Hier dein Text',
                  border: uiComponents.textFieldBorder,
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 20),

            // selection row
            Row(
              children: [
                const Text('Titel: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: uiComponents.textFieldBorder,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedTitle = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Tonart: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                uiComponents.keySelectionDropdown(
                  selectedKey: _selectedKey ?? 'C',
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedKey = newValue;
                      });
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _generate,
                  style: uiComponents.buttonStyle,
                  child: const Text('Generate'),
                ),
                const SizedBox(width: 8),
                _savedSong != null
                    ? ElevatedButton(
                        onPressed: () {
                          showSaveDialog(
                            context: context,
                            onSave: (String groupName) {
                              if (_savedSong != null) {
                                if (groupName.isNotEmpty) {
                                  MultiJsonStorage.saveJson(_savedSong!,
                                      group: groupName);
                                } else {
                                  MultiJsonStorage.saveJson(_savedSong!);
                                }
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                        style: uiComponents.buttonStyle,
                        child: const Text('Save'),
                      )
                    : const SizedBox.shrink()
              ],
            ),
          ],
        ),
      ),
    );
  }
}
