import 'package:P2pChords/UiSettings/page.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/styling/Tiles.dart';
import 'package:flutter/material.dart';

class SongDrawer extends StatefulWidget {
  final Song song;
  final String currentKey;
  final ValueChanged<String> onKeyChanged;

  const SongDrawer({
    super.key,
    required this.song,
    required this.currentKey,
    required this.onKeyChanged,
  });

  @override
  State<SongDrawer> createState() => _SongDrawerState();
}

class _SongDrawerState extends State<SongDrawer> {
  late String _selectedKey;
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
  void initState() {
    super.initState();
    _selectedKey = widget.currentKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          // Styled header with song name and cover image if available
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            width: double.infinity,
            color: theme.primaryColor,
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.song.header.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.song.header.authors.join(', '),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Song Information Section
                _buildSectionHeader(context, 'Lied Informationen'),

                // Key selection (now interactive)
                _buildKeySelector(context),

                _buildDetailItem(
                  context,
                  icon: Icons.speed,
                  title: 'BPM',
                  value: widget.song.header.bpm.toString(),
                ),

                _buildDetailItem(
                  context,
                  icon: Icons.timer,
                  title: 'Rhythmus',
                  value: widget.song.header.timeSignature.toString(),
                ),

                const Divider(),

                // Actions Section
                _buildSectionHeader(context, 'Aktionen'),

                CListTile(
                  title: 'Ansicht anpassen',
                  context: context,
                  icon: Icons.visibility,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UisettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer with app version or copyright
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Text(
              'P2pChords',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeySelector(BuildContext context) {
    final originalKey = widget.song.header.key;
    final isTransposed = _selectedKey != originalKey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note,
                    color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tonart',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedKey,
                        underline: Container(
                          height: 2,
                          color: isTransposed
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedKey = newValue!;
                          });
                          widget.onKeyChanged(newValue!);
                        },
                        items: keys.map<DropdownMenuItem<String>>((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(key),
                          );
                        }).toList(),
                      ),
                      if (isTransposed) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Original: $originalKey)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: highlight
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
