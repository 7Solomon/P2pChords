import 'package:P2pChords/dataManagment/converter/components.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:flutter/material.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedKey;

  void _generate() {
    // Function to handle the button press
    String inputText = _controller.text;
    if (_selectedKey == null) {
      // Handle the case where no key is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wähle Bitte eine Tonart!')),
      );
      return;
    }
    Song song = convertTextToSong(inputText, _selectedKey!);
    //print(song.toMap().toString());
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

            // Key selection row
            Row(
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
