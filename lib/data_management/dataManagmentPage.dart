import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'save_json_in_storage.dart';
import 'SaveJsonPage.dart';

class JsonListPage extends StatefulWidget {
  const JsonListPage({Key? key}) : super(key: key);

  @override
  _JsonListPageState createState() => _JsonListPageState();
}

class _JsonListPageState extends State<JsonListPage> {
  Map<String, Map<String, dynamic>> _allJsons = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllJsons();
  }

  Future<void> _loadAllJsons() async {
    setState(() => _isLoading = true);
    _allJsons = await MultiJsonStorage.loadAllJson();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Lieder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllJsons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allJsons.isEmpty
              ? const Center(child: Text('No saved JSONs'))
              : ListView.builder(
                  itemCount: _allJsons.length,
                  itemBuilder: (context, index) {
                    String key = _allJsons.keys.elementAt(index);
                    return ListTile(
                      title: Text(key),
                      subtitle: Text('Tap to view contents'),
                      onTap: () =>
                          _showJsonDetails(context, key, _allJsons[key]!),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JsonFilePickerPage()),
        ),
        child: const Icon(Icons.add),
        tooltip: 'Neues Lied Hinzufügen',
      ),
    );
  }

  void _showJsonDetails(
      BuildContext context, String key, Map<String, dynamic> jsonData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(key),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: jsonData.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${entry.key}: ${entry.value}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Copy'),
              onPressed: () {
                //Clipboard.setData(ClipboardData(text: jsonData.toString()));
                //ScaffoldMessenger.of(context).showSnackBar(
                //  const SnackBar(content: Text('JSON copied to clipboard')),
                //);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                MultiJsonStorage.removeJson(key).then((_) {
                  Navigator.of(context).pop();
                  _loadAllJsons();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
