import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data_management/save_json_in_storage.dart';
import '../data_management/saveJsonPage.dart';
import 'SongOverviewPage.dart';

class JsonListPage extends StatefulWidget {
  const JsonListPage({Key? key}) : super(key: key);

  @override
  _JsonListPageState createState() => _JsonListPageState();
}

class _JsonListPageState extends State<JsonListPage> {
  Map<String, List<Map<String, String>>> _allGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllJsons();
  }

  Future<void> _loadAllJsons() async {
    setState(() => _isLoading = true);

    _allGroups = await MultiJsonStorage.getAllGroups();
    //_allJsons = await MultiJsonStorage.loadAllJson();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Gruppen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllJsons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allGroups.isEmpty
              ? const Center(child: Text('No saved JSONs'))
              : ListView.builder(
                  itemCount: _allGroups.length,
                  itemBuilder: (context, index) {
                    String key = _allGroups.keys.elementAt(index);
                    return ListTile(
                        title: Text(key),
                        subtitle: const Text(
                            'Klicke um die Songs der Gruppe anzusehen'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Songoverviewpage(
                                  groupName:
                                      key, // The name of the selected group
                                  songs: _allGroups[
                                      key]!, // List of songs in the selected group
                                  onGroupDeleted: _loadAllJsons),
                            ),
                          );
                        });
                  },
                ),
    );
  }
}
