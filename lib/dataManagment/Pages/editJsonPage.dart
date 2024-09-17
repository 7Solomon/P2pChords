import 'dart:convert'; // To handle JSON encoding and decoding
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonEditPage extends StatefulWidget {
  const JsonEditPage(
      {super.key, required this.jsonData, required this.saveJson});

  final Map<String, dynamic> jsonData;
  final void Function(String) saveJson;

  @override
  _JsonEditPageState createState() => _JsonEditPageState();
}

class _JsonEditPageState extends State<JsonEditPage> {
  late TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: jsonEncode(widget.jsonData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit JSON"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Edit JSON",
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => widget.saveJson(_jsonController.text),
              child: const Text("Save JSON"),
            ),
          ],
        ),
      ),
    );
  }
}
