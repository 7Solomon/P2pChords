import 'package:P2pChords/dataManagment/converter/components/section_card.dart';
import 'package:P2pChords/dataManagment/converter/key_validator.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

class InteractiveConverterPage extends StatefulWidget {
  final String rawText;
  final String initialTitle;
  final List<String> initialAuthors;

  const InteractiveConverterPage({
    super.key,
    required this.rawText,
    required this.initialTitle,
    this.initialAuthors = const [],
  });

  @override
  _InteractiveConverterPageState createState() =>
      _InteractiveConverterPageState();
}

class _InteractiveConverterPageState extends State<InteractiveConverterPage> {
  late PreliminarySongData preliminaryData;
  late TextEditingController titleController;
  late TextEditingController keyController;
  late List<TextEditingController> authorControllers;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    keyController = TextEditingController(text: '');

    // Initialize the preliminary data
    preliminaryData = converter.convertTextToSongInteractive(
      widget.rawText,
      widget.initialTitle,
      authors: widget.initialAuthors,
    );

    // Initialize author controllers
    authorControllers = preliminaryData.authors
        .map((author) => TextEditingController(text: author))
        .toList();

    if (authorControllers.isEmpty) {
      authorControllers.add(TextEditingController());
    }

    isLoading = false;
  }

  // Add this method to handle key changes
  void _onKeyChanged(String newKey) {
    // No need to setState here as the UI will update through the controller
    converter.key = newKey;
  }

  @override
  void dispose() {
    titleController.dispose();
    keyController.dispose();
    for (var controller in authorControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewSection() {
    setState(() {
      preliminaryData.sections.add(
        PreliminarySection(
          title: "New Section",
          lines: [],
        ),
      );
    });
  }

  void _addLineToSection(int sectionIndex) {
    setState(() {
      // Add a chord line followed by a lyric line for better usability
      preliminaryData.sections[sectionIndex].lines.add(
        PreliminaryLine(
          text: "",
          isChordLine: true,
        ),
      );
      preliminaryData.sections[sectionIndex].lines.add(
        PreliminaryLine(
          text: "",
          isChordLine: false,
        ),
      );
    });
  }

  void _toggleLineType(int sectionIndex, int lineIndex) {
    setState(() {
      preliminaryData.sections[sectionIndex].lines[lineIndex].isChordLine =
          !preliminaryData.sections[sectionIndex].lines[lineIndex].isChordLine;
    });
  }

  void _removeSection(int index) {
    setState(() {
      preliminaryData.sections.removeAt(index);
    });
  }

  void _removeLine(int sectionIndex, int lineIndex) {
    setState(() {
      preliminaryData.sections[sectionIndex].lines.removeAt(lineIndex);
    });
  }

  void _updateLineText(int sectionIndex, int lineIndex, String newText) {
    setState(() {
      preliminaryData.sections[sectionIndex].lines[lineIndex].text = newText;
    });
  }

  void _updateSectionTitle(int sectionIndex, String newTitle) {
    setState(() {
      preliminaryData.sections[sectionIndex].title = newTitle;
    });
  }

  void _moveLine(int sectionIndex, int lineIndex) {
    // Move line at lineIndex and lineIndex+1 down one spot
    if (lineIndex < preliminaryData.sections[sectionIndex].lines.length - 1) {
      setState(() {
        final line =
            preliminaryData.sections[sectionIndex].lines.removeAt(lineIndex);
        preliminaryData.sections[sectionIndex].lines
            .insert(lineIndex + 1, line);
      });
    }
  }

  void _addAuthorField() {
    setState(() {
      authorControllers.add(TextEditingController());
    });
  }

  void _removeAuthorField(int index) {
    setState(() {
      authorControllers.removeAt(index);
    });
  }

  Song _finalizeSong() {
    // Update the song data from controllers
    final authors = authorControllers
        .map((controller) => controller.text)
        .where((text) => text.isNotEmpty)
        .toList();

    final keyValue = keyController.text.trim();

    preliminaryData = PreliminarySongData(
      originalText: preliminaryData.originalText,
      sections: preliminaryData.sections,
      title: titleController.text,
      authors: authors,
      key: keyValue,
    );

    // The key is stored in converter and in preliminaryData
    return converter.finalizeSong(preliminaryData, keyValue);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Song Conversion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final song = _finalizeSong();
              bool result = await MultiJsonStorage.saveJson(song);
              if (result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Erfolgreich gespeichert: ${song.header.name}')),
                );
              } else {
                // Handle error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fehler beim Speichern!')),
                );
              }
            },
            tooltip: 'Song speichern',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song metadata fields
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Song Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Song Title',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    KeyInputPreview(
                      keyController: keyController,
                      songData: preliminaryData,
                      onKeyChanged: _onKeyChanged,
                    ),

                    const SizedBox(height: 16),

                    // Authors section
                    const Text('Authors',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    for (int i = 0; i < authorControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: authorControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Author ${i + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: authorControllers.length > 1
                                  ? () => _removeAuthorField(i)
                                  : null,
                            ),
                          ],
                        ),
                      ),

                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Author'),
                      onPressed: _addAuthorField,
                    ),
                  ],
                ),
              ),
            ),

            // Original text preview (collapsible)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: const Text('Original Text'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      preliminaryData.originalText,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Song Sections',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            // List of sections using the custom widget
            for (int sectionIndex = 0;
                sectionIndex < preliminaryData.sections.length;
                sectionIndex++)
              SectionCard(
                section: preliminaryData.sections[sectionIndex],
                sectionIndex: sectionIndex,
                onUpdateSectionTitle: _updateSectionTitle,
                onRemoveSection: _removeSection,
                onUpdateLineText: _updateLineText,
                onToggleLineType: _toggleLineType,
                onRemoveLine: _removeLine,
                onAddLine: _addLineToSection,
                onMoveLine: _moveLine,
              ),

            // Add new section button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Section'),
                onPressed: _addNewSection,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
