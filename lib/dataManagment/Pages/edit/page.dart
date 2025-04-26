import 'dart:convert';
import 'package:P2pChords/dataManagment/Pages/edit/style.dart';
// Import FilePickerUtil
import 'package:P2pChords/dataManagment/Pages/file_picker.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:P2pChords/styling/SpeedDial.dart';
import 'package:P2pChords/utils/notification_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

// Import converter components and functions
import 'package:P2pChords/dataManagment/converter/functions.dart';
import 'package:P2pChords/dataManagment/converter/components/section_card.dart';
import 'package:P2pChords/dataManagment/converter/key_validator.dart';
import 'package:P2pChords/dataManagment/converter/components/line_item.dart'; // Ensure LineItem is imported if needed directly

// Import ChordUtils for nashvilleToChord
import 'package:P2pChords/dataManagment/chords/chord_utils.dart';

class SongEditPage extends StatefulWidget {
  const SongEditPage({
    super.key,
    required this.song,
    this.group,
  });

  final Song song;
  final String? group;

  @override
  _SongEditPageState createState() => _SongEditPageState();
}

class _SongEditPageState extends State<SongEditPage> {
  // State variables for converter approach
  late PreliminarySongData preliminaryEditData;
  late TextEditingController titleController; // Renamed from _nameController
  late TextEditingController keyController; // Renamed from _keyController
  late List<TextEditingController>
      authorControllers; // Renamed from _authorControllers
  late SongConverter converter;
  bool isLoading = true;
  bool _isSaving = false; // Flag to prevent multiple saves

  // Keep original BPM and Time Signature to preserve them on save
  int? _originalBpm;
  String? _originalTimeSignature;

  @override
  void initState() {
    super.initState();
    converter = SongConverter();
    _originalBpm = widget.song.header.bpm;
    _originalTimeSignature = widget.song.header.timeSignature;
    _convertSongToPreliminaryData(widget.song);
  }

  // Helper to reconstruct the chord line text from Chord objects
  // Modified to accept songKey and convert Nashville back to standard chords
  String _reconstructChordLine(
      List<Chord> chords, int lyricLength, String songKey) {
    if (chords.isEmpty) return "";
    // Sort chords by position
    chords.sort((a, b) => a.position.compareTo(b.position));

    StringBuffer buffer = StringBuffer();
    int currentPos = 0;
    for (var chord in chords) {
      // Add spaces to reach the chord position
      if (chord.position > currentPos) {
        buffer.write(' ' * (chord.position - currentPos));
      } else if (chord.position < currentPos) {
        // Handle overlapping chords? For now, just append with a space if needed
        if (buffer.isNotEmpty && buffer.toString()[buffer.length - 1] != ' ') {
          buffer.write(' ');
        }
      }
      // Convert Nashville value back to standard chord notation
      String standardChord = ChordUtils.nashvilleToChord(chord.value, songKey);
      buffer.write(standardChord);
      currentPos = chord.position +
          standardChord
              .length; // Update position based on standard chord length
    }
    return buffer.toString().trimRight(); // Trim trailing spaces
  }

  void _convertSongToPreliminaryData(Song song) {
    List<PreliminarySection> sections = [];
    for (var songSection in song.sections) {
      List<PreliminaryLine> prelimLines = [];
      for (var lineData in songSection.lines) {
        // Create the chord line text using standard chords converted from Nashville
        // Pass the song's key here
        String chordLineText = _reconstructChordLine(
            lineData.chords, lineData.lyrics.length, song.header.key);

        // Add chord line (only if there are chords)
        if (chordLineText.isNotEmpty) {
          prelimLines.add(PreliminaryLine(
            text: chordLineText,
            isChordLine: true,
          ));
        }
        // Add lyric line
        prelimLines.add(PreliminaryLine(
          text: lineData.lyrics,
          isChordLine: false, // Lyric line is never a chord line initially here
        ));
      }
      sections.add(PreliminarySection(
        title: songSection.title,
        lines: prelimLines,
      ));
    }

    // Initialize state variables
    preliminaryEditData = PreliminarySongData(
      originalText: '', // Not directly applicable when editing structured Song
      sections: sections,
      title: song.header.name,
      authors: song.header.authors,
      key: song.header.key,
    );

    titleController = TextEditingController(text: preliminaryEditData.title);
    keyController = TextEditingController(text: preliminaryEditData.key);
    // Use new name for consistency
    authorControllers = preliminaryEditData.authors
        .map((author) => TextEditingController(text: author))
        .toList();
    if (authorControllers.isEmpty) {
      authorControllers.add(TextEditingController());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    keyController.dispose();
    // Dispose new author controllers list
    for (var controller in authorControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Callbacks for SectionCard (similar to InteractiveConverterPage) ---

  void _onKeyChanged(String newKey) {
    // Trigger rebuild to update chord previews if key changes
    if (mounted) {
      setState(() {});
    }
  }

  void _splitChordLyricPair(int sectionIndex, int chordLineIndex) {
    setState(() {
      final section = preliminaryEditData.sections[sectionIndex];
      // Ensure wasSplit is set to true for both lines when splitting
      if (chordLineIndex < section.lines.length) {
        section.lines[chordLineIndex].wasSplit =
            true; // Mark chord line as split
      }
      if (chordLineIndex + 1 < section.lines.length) {
        section.lines[chordLineIndex + 1].wasSplit =
            true; // Mark lyric line as split
      }
    });
  }

  // --- NEW: Callback to combine lines ---
  void _combineLines(int sectionIndex, int chordLineIndex) {
    setState(() {
      final section = preliminaryEditData.sections[sectionIndex];
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

  void _addNewSection() {
    // Use simple add for now, can add dialog later if needed
    setState(() {
      preliminaryEditData.sections.add(
        PreliminarySection(
          title: "New Section",
          // Add an empty chord/lyric pair
          lines: [
            PreliminaryLine(text: "", isChordLine: true, wasSplit: true),
            PreliminaryLine(text: "", isChordLine: false, wasSplit: true),
          ],
        ),
      );
    });
  }

  void _addLineToSection(int sectionIndex) {
    setState(() {
      // Add a chord line followed by a lyric line, marked as split initially
      preliminaryEditData.sections[sectionIndex].lines.add(
        PreliminaryLine(
          text: "",
          isChordLine: true,
          wasSplit: true, // Treat as individual lines initially
        ),
      );
      preliminaryEditData.sections[sectionIndex].lines.add(
        PreliminaryLine(
          text: "",
          isChordLine: false,
          wasSplit: true, // Treat as individual lines initially
        ),
      );
    });
  }

  void _toggleLineType(int sectionIndex, int lineIndex) {
    setState(() {
      final line = preliminaryEditData.sections[sectionIndex].lines[lineIndex];
      line.isChordLine = !line.isChordLine;
      // If toggled, it's definitely acting as a single line
      line.wasSplit = true;
    });
  }

  void _removeSection(int index) {
    // Add confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
            'Are you sure you want to delete "${preliminaryEditData.sections[index].title}"?'),
        actions: [
          TextButton(
            style: UIStyle.secondaryButton,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: UIStyle.button.copyWith(
                backgroundColor: WidgetStateProperty.all(UIStyle.error)),
            onPressed: () {
              setState(() {
                preliminaryEditData.sections.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _removeLine(int sectionIndex, int lineIndex) {
    setState(() {
      preliminaryEditData.sections[sectionIndex].lines.removeAt(lineIndex);
      // Optional: If section becomes empty, add a default pair?
      if (preliminaryEditData.sections[sectionIndex].lines.isEmpty) {
        _addLineToSection(sectionIndex); // Add a default pair back
      }
    });
  }

  void _updateLineText(int sectionIndex, int lineIndex, String newText) {
    // Direct update, no need for setState if controller handles it, but
    // PreliminaryLine doesn't use controllers directly, so setState is needed.
    setState(() {
      preliminaryEditData.sections[sectionIndex].lines[lineIndex].text =
          newText;
    });
  }

  void _updateSectionTitle(int sectionIndex, String newTitle) {
    // Direct update, PreliminarySection doesn't use controller, so setState needed.
    setState(() {
      preliminaryEditData.sections[sectionIndex].title = newTitle;
    });
  }

  void _moveLine(int sectionIndex, int lineIndex) {
    // This needs careful implementation depending on whether it's a single line or a pair
    // For simplicity, let's assume moving single lines for now.
    // Moving pairs requires identifying the pair and moving both.
    // Let's implement moving a single line down.
    if (lineIndex <
        preliminaryEditData.sections[sectionIndex].lines.length - 1) {
      if (preliminaryEditData
          .sections[sectionIndex].lines[lineIndex].wasSplit) {
        setState(() {
          final line = preliminaryEditData.sections[sectionIndex].lines
              .removeAt(lineIndex);
          preliminaryEditData.sections[sectionIndex].lines
              .insert(lineIndex + 2, line); // Move down by 2 for pair
        });
      } else {
        SnackService().showError(
            'Nur eine Zeile kann verschoben werden, schere ist noch nicht implmentiert!');
      }
    } else {
      // Just move the single line down
      setState(() {
        final line = preliminaryEditData.sections[sectionIndex].lines
            .removeAt(lineIndex);
        preliminaryEditData.sections[sectionIndex].lines
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
    // Prevent removing the last field if you want at least one
    if (authorControllers.length > 1) {
      setState(() {
        // Dispose the controller before removing
        authorControllers[index].dispose();
        authorControllers.removeAt(index);
      });
    } else {
      // Optionally clear the text of the last controller
      setState(() {
        authorControllers[index].clear();
      });
    }
  }

  // --- Save Changes ---
  // Returns true if save was successful or not needed, false if validation failed
  Future<bool> _saveChanges({bool popOnSuccess = true}) async {
    if (_isSaving) return false; // Prevent concurrent saves
    setState(() {
      _isSaving = true;
    });

    final dataLoadeProvider =
        Provider.of<DataLoadeProvider>(context, listen: false);

    // Update preliminaryData from controllers before finalizing
    final authors = authorControllers
        .map((controller) => controller.text.trim()) // Trim whitespace
        .where((text) => text.isNotEmpty)
        .toList();
    final key = keyController.text.trim();
    final title = titleController.text.trim();

    if (key.isEmpty) {
      SnackService().showError('Song Key cannot be empty!');
      setState(() {
        _isSaving = false;
      });
      return false;
    }
    if (title.isEmpty) {
      SnackService().showError('Song Title cannot be empty!');
      setState(() {
        _isSaving = false;
      });
      return false;
    }

    // Create a temporary updated PreliminarySongData instance for finalization
    final currentPreliminaryData = PreliminarySongData(
        originalText: preliminaryEditData
            .originalText, // Keep original if needed, or empty
        sections: preliminaryEditData.sections, // Use the current state
        title: title,
        authors: authors,
        key: key);

    // Convert PreliminarySongData back to a Song object using the converter
    // The finalizeSong method uses extractChords which correctly converts
    // standard chords back to Nashville based on the provided key.
    Song intermediateSong = converter.finalizeSong(currentPreliminaryData, key);

    // Preserve original hash if editing, otherwise generate based on the *final* song content.
    // The hash from finalizeSong is based on originalText which is empty/irrelevant here.
    String finalHash =
        widget.song.hash != sha256.convert(utf8.encode('empty')).toString()
            ? widget.song
                .hash // Keep original hash if it wasn't the default empty one
            : sha256
                .convert(utf8.encode(intermediateSong.toMap().toString()))
                .toString(); // Generate new hash otherwise

    // Create the final Song object with the correct hash and preserved metadata
    final finalUpdatedSong = Song(
      hash: finalHash,
      header: SongHeader(
        // Reconstruct header including potentially missing fields
        name: intermediateSong.header.name, // Use name from finalized data
        key: intermediateSong.header.key, // Use key from finalized data
        authors:
            intermediateSong.header.authors, // Use authors from finalized data
        bpm: _originalBpm, // Preserve original BPM
        timeSignature: _originalTimeSignature, // Preserve original TimeSig
      ),
      sections: intermediateSong.sections, // Use sections from finalized data
    );

    bool result = true; // Assume success if no changes needed saving

    if (dataLoadeProvider.songs.containsKey(widget.song.hash) &&
        widget.song.hash != finalUpdatedSong.hash) {
      // Remove the old version only if the hash has changed
      await dataLoadeProvider.removeSong(widget.song.hash);
    }
    // Add the new/updated song
    result = await dataLoadeProvider.addSong(finalUpdatedSong,
        groupName: widget.group);

    setState(() {
      _isSaving = false;
    });

    if (result) {
      // Only show success if something was actually saved
      SnackService()
          .showSuccess('Gespeichert: ${finalUpdatedSong.header.name}');

      if (popOnSuccess && mounted) {
        Navigator.of(context).pop();
      }
      return true; // Indicate success
    } else {
      SnackService().showError('Fehler beim Speichern!');
      return false; // Indicate failure
    }
  }

  // --- Load Song from File (Example Integration) ---
  Future<void> _loadSongFromFile() async {
    // 1. Ask user if they want to save current changes
    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Änderungen speichern?'),
          content: const Text(
              'Möchten Sie die aktuellen Änderungen speichern, bevor Sie einen neuen Song laden?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop(false); // Don't proceed
              },
            ),
            TextButton(
              child: const Text('Verwerfen'),
              onPressed: () {
                Navigator.of(context).pop(true); // Proceed without saving
              },
            ),
            ElevatedButton(
              child: const Text('Speichern'),
              onPressed: () async {
                // Attempt to save changes
                bool saveSuccess =
                    await _saveChanges(popOnSuccess: false); // Don't pop here
                if (saveSuccess && mounted) {
                  Navigator.of(context)
                      .pop(true); // Proceed after successful save
                } else if (!saveSuccess && mounted) {
                  // Save failed (e.g., validation error), stay on page
                  // Optionally show another message or just let the _saveChanges handle it
                  Navigator.of(context)
                      .pop(false); // Do not proceed if save fails
                }
              },
            ),
          ],
        );
      },
    );

    // 2. If user didn't cancel, proceed to pick file
    if (shouldProceed == true && mounted) {
      final Song? loadedSong = await FilePickerUtil.pickSongFile(context);

      if (loadedSong != null && mounted) {
        // Navigate to a new instance of the editor with the loaded song
        Navigator.pushReplacement(
          // Use pushReplacement to replace the current editor
          context,
          MaterialPageRoute(
            builder: (context) => SongEditPage(
              song: loadedSong,
              // Decide if you want to associate it with the current group or not
              group: widget.group,
            ),
          ),
        );
      } else if (loadedSong == null) {
        // Handle case where no file was picked or parsing failed
        SnackService()
            .showInfo('Keine Songdatei ausgewählt oder Laden fehlgeschlagen.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Loading Editor..."),
          backgroundColor: UIStyle.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Song Editieren"),
        backgroundColor: UIStyle.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ))
                : const Icon(Icons.save),
            onPressed:
                _isSaving ? null : () => _saveChanges(), // Disable while saving
            tooltip: 'Save Changes',
          ),
        ],
      ),
      // Keep SpeedDial or simplify to just a save button in AppBar/Body
      floatingActionButton: CSpeedDial(theme: Theme.of(context), children: [
        SpeedDialChild(
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ))
              : const Icon(Icons.save),
          backgroundColor: UIStyle.primary,
          foregroundColor: Colors.white,
          label: 'Save Changes',
          onTap:
              _isSaving ? null : () => _saveChanges(), // Disable while saving
        ),
        // Uncommented and updated Load Song File button
        SpeedDialChild(
          child: const Icon(Icons.file_upload),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          label: 'Load Song File',
          onTap: _loadSongFromFile, // Call the updated load function
        ),
      ]),

      // Remove other buttons or adapt them
      // SpeedDialChild(
      //   child: const Icon(Icons.code),
      //   backgroundColor: UIStyle.primary,
      //   foregroundColor: Colors.white,
      //   label: 'Show Raw JSON', // TODO: Adapt if needed
      //   onTap: () {/* Show preliminaryEditData JSON */},
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(UIStyle.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Song Header Section - Simplified for Converter approach
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: UIStyle.largeSpacing),
                child: Padding(
                  padding: UIStyle.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Song Information', style: UIStyle.heading),
                      const SizedBox(height: UIStyle.spacing),

                      // Song Title
                      TextField(
                        controller: titleController,
                        decoration: UIStyle.inputDecoration('Song Title'),
                      ),
                      const SizedBox(height: UIStyle.spacing),

                      // Key Input using KeyInputPreview
                      KeyInputPreview(
                        keyController: keyController,
                        songData:
                            preliminaryEditData, // Pass the preliminary data
                        onKeyChanged: _onKeyChanged,
                      ),
                      const SizedBox(height: UIStyle.spacing),

                      // Authors Section
                      const Text('Authoren', style: UIStyle.subheading),
                      const SizedBox(height: UIStyle.smallSpacing),

                      // Use new authorControllers list
                      ...authorControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: UIStyle.smallSpacing),
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
                                onPressed: () =>
                                    _removeAuthorField(index), // Use new method
                                icon: const Icon(Icons.remove_circle_outline),
                                color: UIStyle.error,
                                tooltip: 'Remove Author',
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: UIStyle.smallSpacing),
                      ElevatedButton.icon(
                        onPressed: _addAuthorField, // Use new method
                        icon: const Icon(Icons.add),
                        label: const Text('Author Hinzufügen'),
                        style: UIStyle.secondaryButton,
                      ),
                    ],
                  ),
                ),
              ),

              // Sections Heading with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Sections',
                        style: UIStyle.heading,
                        overflow: TextOverflow.ellipsis),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addNewSection, // Use new method
                    icon: const Icon(Icons.add),
                    label: const Text('Hinzufügen'),
                    style: UIStyle.button,
                  ),
                ],
              ),
              const SizedBox(height: UIStyle.spacing),

              // Song Sections using SectionCard
              ListView.builder(
                  shrinkWrap: true, // Important inside SingleChildScrollView
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable inner scrolling
                  itemCount: preliminaryEditData.sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = preliminaryEditData.sections[sectionIndex];
                    return SectionCard(
                      key: ValueKey('section_$sectionIndex'), // Use unique keys
                      section: section,
                      sectionIndex: sectionIndex,
                      songKey: keyController.text, // Pass current key
                      onUpdateSectionTitle: _updateSectionTitle,
                      onRemoveSection: _removeSection,
                      onUpdateLineText: _updateLineText,
                      onToggleLineType: _toggleLineType,
                      onRemoveLine: _removeLine,
                      onAddLine: _addLineToSection,
                      onMoveLine: _moveLine, // Note: Basic implementation
                      onSplitChordLyricPair: _splitChordLyricPair,
                      onCombineLines: _combineLines,
                    );
                  }),

              // Remove old section rendering loop
              // ..._editedSong.sections.asMap().entries.map((sectionEntry) { ... })

              // Save Button at bottom (optional, already in AppBar/FAB)
              const SizedBox(height: UIStyle.spacing),
              // Align(
              //   alignment: Alignment.center,
              //   child: SizedBox(
              //     child: ElevatedButton.icon(
              //       onPressed: _saveChanges,
              //       icon: const Icon(Icons.save),
              //       label: const Text('Save Changes'),
              //       style: UIStyle.secondaryButton,
              //     ),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
