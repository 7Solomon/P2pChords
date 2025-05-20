import 'package:P2pChords/dataManagment/data_base/song_detail_view.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

class SongListView extends StatelessWidget {
  final List<Song> songs;

  const SongListView({
    super.key,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    // Sort songs by title for better usability
    songs.sort((a, b) => a.header.name.compareTo(b.header.name));

    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Verfügbare Songs ${songs.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Song list
        Expanded(
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return SongListItem(
                song: song,
                index: index,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongDetailView(
                        songs: songs,
                        initialSongIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SongListItem extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;

  const SongListItem({
    Key? key,
    required this.song,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            (index + 1).toString(),
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        title: Text(
          song.header.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artists: ${song.header.authors.join(', ')}'),
            Text('${song.sections.length} sections'),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).primaryColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
