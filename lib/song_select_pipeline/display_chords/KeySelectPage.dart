import 'package:flutter/material.dart';

class KeySelectionPage extends StatefulWidget {
  const KeySelectionPage({super.key});

  @override
  _KeySelectionPageState createState() => _KeySelectionPageState();
}

class _KeySelectionPageState extends State<KeySelectionPage> {
  String selectedKey = 'C'; // Default selected key

  final List<String> keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key'),
      ),
      body: Center(
        // Center the entire content
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            const Text(
              'Wähle eine Tonart:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedKey,
              onChanged: (String? newKey) {
                setState(() {
                  selectedKey = newKey!;
                });
              },
              items: keys.map<DropdownMenuItem<String>>((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(key),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedKey);
              },
              child: const Text('Auswählen'),
            ),
          ],
        ),
      ),
    );
  }
}
