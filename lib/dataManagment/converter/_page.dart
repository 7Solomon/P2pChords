
/*
import 'dart:convert';

import 'package:P2pChords/dataManagment/converter/components/section_card.dart';
import 'package:P2pChords/dataManagment/converter/key_validator.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:provider/provider.dart';

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
  late SongConverter converter;
  late List<TextEditingController> authorControllers;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    keyController = TextEditingController(text: '');
    converter = SongConverter();

    // Initialize data asynchronously
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('GET DATA');
    //  Get the first conversion with real-time positioning
    PreliminarySongData initialPreliminaryData =
        converter.convertTextToSongInteractive(
      widget.rawText,
      widget.initialTitle,
      authors: widget.initialAuthors,
      key: '', // Start with empty key
    );

    print(
        "INITIAL CONVERSION COMPLETE: ${initialPreliminaryData.sections.length} sections");

    // Process sections to handle duplicates with interactive dialog
    final processedSections = await processDuplicateSectionsInteractive(
      initialPreliminaryData.sections,
      context: context,
      showDialog: true,
    );

    // update
    preliminaryData = PreliminarySongData(
      originalText: initialPreliminaryData.originalText,
      sections: processedSections,
      title: initialPreliminaryData.title,
      authors: initialPreliminaryData.authors,
      key: initialPreliminaryData.key,
    );

    // Initialize author controllers
    authorControllers = preliminaryData.authors
        .map((author) => TextEditingController(text: author))
        .toList();

    if (authorControllers.isEmpty) {
      authorControllers.add(TextEditingController());
    }

    setState(() {
      isLoading = false;
    });
  }

  // Add this method to handle key changes
  void _onKeyChanged(String newKey) {
    if (newKey.trim().isEmpty) {
      return;
    }

    print("KEY CHANGED: Reconverting with key '$newKey'");

    // Trigger real-time reconversion with the new key
    setState(() {
      PreliminarySongData reconvertedData =
          converter.convertTextToSongInteractive(
        preliminaryData.originalText,
        titleController.text,
        authors: authorControllers
            .map((controller) => controller.text)
            .where((text) => text.isNotEmpty)
            .toList(),
        key: newKey,
      );

      // Update the preliminary data with new positioning
      preliminaryData = reconvertedData;
    });
  }

  void _splitChordLyricPair(int sectionIndex, int chordLineIndex) {
    setState(() {
      final section = preliminaryData.sections[sectionIndex];

      // Ensure wasSplit is set to true for both lines when splitting
      if (chordLineIndex < section.lines.length) {
        section.lines[chordLineIndex].isChordLine =
            true; // Ensure type is correct
        section.lines[chordLineIndex].wasSplit = true; // Set the flag

        // Clean the chord line text if it contains special characters
        String currentText = section.lines[chordLineIndex].text;
        if (converter.isChordLine(currentText)) {
          section.lines[chordLineIndex].text = cleanChordLineText(currentText);
        }
      }

      if (chordLineIndex + 1 < section.lines.length) {
        section.lines[chordLineIndex + 1].isChordLine =
            false; // Ensure type is correct
        section.lines[chordLineIndex + 1].wasSplit = true; // Set the flag
      }
    });
  }

  void _combineLines(int sectionIndex, int chordLineIndex) {
    setState(() {
      final section = preliminaryData.sections[sectionIndex];
      // Ensure wasSplit is set to false for both lines when combining
      if (chordLineIndex < section.lines.length) {
        section.lines[chordLineIndex].wasSplit =
            false; // Mark chord line as combined
      }
      // Check bounds for lyric line
      if (chordLineIndex + 1 < section.lines.length &&
          !section.lines[chordLineIndex + 1].isChordLine) {
        // Ensure it's a lyric line
        section.lines[chordLineIndex + 1].wasSplit =
            false; // Mark lyric line as combined
      }
    });
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
      if (preliminaryData.sections[sectionIndex].lines[lineIndex].isChordLine) {
        String currentText =
            preliminaryData.sections[sectionIndex].lines[lineIndex].text;
        preliminaryData.sections[sectionIndex].lines[lineIndex].text =
            cleanChordLineText(currentText);
      }
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

  void _moveSectionUp(int sectionIndex) {
    if (sectionIndex > 0) {
      setState(() {
        final section = preliminaryData.sections.removeAt(sectionIndex);
        preliminaryData.sections.insert(sectionIndex - 1, section);
      });
    }
  }

  void _moveSectionDown(int sectionIndex) {
    if (sectionIndex < preliminaryData.sections.length - 1) {
      setState(() {
        final section = preliminaryData.sections.removeAt(sectionIndex);
        preliminaryData.sections.insert(sectionIndex + 1, section);
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
    final dataLoadeProvider = Provider.of<DataLoadeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Song Conversion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final song = _finalizeSong();
              bool result = await dataLoadeProvider.addSong(song);
              if (result) {
                SnackService().showSuccess(
                    'Erfolgreich gespeichert: ${song.header.name}');
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                SnackService().showError('Fehler beim Speichern!');
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
                key: ValueKey(
                    'section_$sectionIndex'), // Add key for state management
                section: preliminaryData.sections[sectionIndex],
                sectionIndex: sectionIndex,
                onUpdateSectionTitle: _updateSectionTitle,
                onRemoveSection: _removeSection,
                onUpdateLineText: _updateLineText,
                onToggleLineType: _toggleLineType,
                onRemoveLine: _removeLine,
                onAddLine: _addLineToSection,
                onMoveSectionUp: _moveSectionUp,
                onMoveSectionDown: _moveSectionDown,
                onMoveLine: _moveLine,
                onSplitChordLyricPair: _splitChordLyricPair,
                onCombineLines: _combineLines,
                songKey: keyController.text,
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
*/