import 'dart:convert';
import 'package:P2pChords/dataManagment/Pages/edit/editor_component.dart';
import 'package:P2pChords/dataManagment/Pages/edit/style.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

import 'package:flutter/material.dart';

class SongEditPage extends StatefulWidget {
  const SongEditPage({super.key, required this.song, required this.saveSong});

  final Song song;
  final void Function(Song) saveSong;

  @override
  _SongEditPageState createState() => _SongEditPageState();
}

class _SongEditPageState extends State<SongEditPage> {
  late Song _editedSong;
  late TextEditingController _nameController;
  late TextEditingController _keyController;
  late TextEditingController _bpmController;
  late TextEditingController _timeSignatureController;

  final _authorControllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _editedSong = Song.fromMap(widget.song.toMap());
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _editedSong.header.name);
    _keyController = TextEditingController(text: _editedSong.header.key);
    _bpmController =
        TextEditingController(text: _editedSong.header.bpm?.toString() ?? '');
    _timeSignatureController =
        TextEditingController(text: _editedSong.header.timeSignature ?? '');

    // Set up author controllers
    for (var author in _editedSong.header.authors) {
      _authorControllers.add(TextEditingController(text: author));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _bpmController.dispose();
    _timeSignatureController.dispose();
    for (var controller in _authorControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    // Update the header data
    final updatedHeader = SongHeader(
      name: _nameController.text,
      key: _keyController.text,
      bpm: _bpmController.text.isNotEmpty
          ? int.tryParse(_bpmController.text)
          : null,
      timeSignature: _timeSignatureController.text.isNotEmpty
          ? _timeSignatureController.text
          : null,
      authors: _authorControllers
          .map((c) => c.text)
          .where((text) => text.isNotEmpty)
          .toList(),
    );

    // Create updated song with the current sections and new header
    final updatedSong = Song(
      hash: _editedSong.hash,
      header: updatedHeader,
      sections: _editedSong.sections,
    );

    widget.saveSong(updatedSong);
  }

  void _addNewSection() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Section'),
          content: TextField(
            controller: titleController,
            decoration:
                UIStyle.inputDecoration('Section Name (e.g., Verse 2, Chorus)'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              style: UIStyle.secondaryButton,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: UIStyle.button,
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    final newSection = SongSection(
                      title: titleController.text,
                      lines: [LyricLine(lyrics: '', chords: [])],
                    );
                    _editedSong.sections.add(newSection);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addNewLine(int sectionIndex) {
    setState(() {
      _editedSong.sections[sectionIndex].lines.add(
        LyricLine(lyrics: '', chords: []),
      );
    });
  }

  void _updateLine(int sectionIndex, int lineIndex, LyricLine updatedLine) {
    setState(() {
      _editedSong.sections[sectionIndex].lines[lineIndex] = updatedLine;
    });
  }

  void _deleteLine(int sectionIndex, int lineIndex) {
    setState(() {
      _editedSong.sections[sectionIndex].lines.removeAt(lineIndex);
      // If this was the last line, add an empty one
      if (_editedSong.sections[sectionIndex].lines.isEmpty) {
        _editedSong.sections[sectionIndex].lines.add(
          LyricLine(lyrics: '', chords: []),
        );
      }
    });
  }

  void _deleteSection(int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
            'Are you sure you want to delete "${_editedSong.sections[sectionIndex].title}"?'),
        actions: [
          TextButton(
            style: UIStyle.secondaryButton,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: UIStyle.button.copyWith(
                backgroundColor: MaterialStateProperty.all(UIStyle.error)),
            onPressed: () {
              setState(() {
                _editedSong.sections.removeAt(sectionIndex);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addAuthor() {
    setState(() {
      _authorControllers.add(TextEditingController());
    });
  }

  void _removeAuthor(int index) {
    setState(() {
      _authorControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Song"),
        backgroundColor: UIStyle.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            tooltip: 'Save Changes',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Raw JSON'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ')
                          .convert(_editedSong.toMap()),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      style: UIStyle.button,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.code),
            tooltip: 'View JSON',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(UIStyle.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Song Header Section
              Container(
                decoration: UIStyle.cardDecoration,
                padding: UIStyle.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Song Details', style: UIStyle.heading),
                    SizedBox(height: UIStyle.spacing),

                    // Song Name
                    TextField(
                      controller: _nameController,
                      decoration: UIStyle.inputDecoration('Song Name'),
                    ),
                    SizedBox(height: UIStyle.spacing),

                    // Row for Key, BPM, Time Signature
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _keyController,
                            decoration: UIStyle.inputDecoration('Key'),
                          ),
                        ),
                        SizedBox(width: UIStyle.spacing),
                        Expanded(
                          child: TextField(
                            controller: _bpmController,
                            decoration: UIStyle.inputDecoration('BPM'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: UIStyle.spacing),
                        Expanded(
                          child: TextField(
                            controller: _timeSignatureController,
                            decoration:
                                UIStyle.inputDecoration('Time Signature'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: UIStyle.spacing),

                    // Authors Section
                    Text('Authors', style: UIStyle.subheading),
                    SizedBox(height: UIStyle.smallSpacing),

                    ..._authorControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;

                      return Padding(
                        padding: EdgeInsets.only(bottom: UIStyle.smallSpacing),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: UIStyle.inputDecoration(
                                    'Author ${index + 1}'),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeAuthor(index),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: UIStyle.error,
                            ),
                          ],
                        ),
                      );
                    }),

                    SizedBox(height: UIStyle.smallSpacing),
                    ElevatedButton.icon(
                      onPressed: _addAuthor,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Author'),
                      style: UIStyle.secondaryButton,
                    ),
                  ],
                ),
              ),

              SizedBox(height: UIStyle.largeSpacing),

              // Sections Heading with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Song Sections', style: UIStyle.heading),
                  ElevatedButton.icon(
                    onPressed: _addNewSection,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Section'),
                    style: UIStyle.button,
                  ),
                ],
              ),
              SizedBox(height: UIStyle.spacing),

              // Song Sections
              ..._editedSong.sections.asMap().entries.map((sectionEntry) {
                final sectionIndex = sectionEntry.key;
                final section = sectionEntry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: UIStyle.spacing),
                  decoration: UIStyle.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Container(
                        padding: UIStyle.cardPadding,
                        decoration: BoxDecoration(
                          color: UIStyle.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(section.title, style: UIStyle.subheading),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _addNewLine(sectionIndex),
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: UIStyle.primary,
                                  tooltip: 'Add Line',
                                ),
                                IconButton(
                                  onPressed: () => _deleteSection(sectionIndex),
                                  icon: const Icon(Icons.delete_outline),
                                  color: UIStyle.error,
                                  tooltip: 'Delete Section',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Section Lines
                      Padding(
                        padding: UIStyle.cardPadding,
                        child: Column(
                          children:
                              section.lines.asMap().entries.map((lineEntry) {
                            final lineIndex = lineEntry.key;
                            final line = lineEntry.value;

                            return Container(
                              margin: EdgeInsets.only(bottom: UIStyle.spacing),
                              padding: EdgeInsets.all(UIStyle.smallSpacing),
                              decoration: BoxDecoration(
                                border: Border.all(color: UIStyle.divider),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Line Number with Delete Button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Line ${lineIndex + 1}',
                                        style: UIStyle.caption,
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteLine(
                                            sectionIndex, lineIndex),
                                        icon: const Icon(Icons.delete_outline),
                                        color: UIStyle.error,
                                        iconSize: 20,
                                        tooltip: 'Delete Line',
                                        constraints: const BoxConstraints(
                                          minHeight: 36,
                                          minWidth: 36,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Visual Chord Editor Component
                                  ChordEditorComponent(
                                    line: line,
                                    songKey: _keyController.text,
                                    onLineChanged: (updatedLine) => _updateLine(
                                        sectionIndex, lineIndex, updatedLine),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Save Button at bottom
              SizedBox(height: UIStyle.spacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: UIStyle.button,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
