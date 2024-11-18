import 'package:P2pChords/dataManagment/storageManager.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';
import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/loadData.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:core';

class UisettingsPage extends StatefulWidget {
  const UisettingsPage({Key? key}) : super(key: key);

  @override
  _UisettingsPageState createState() => _UisettingsPageState();
}

class _UisettingsPageState extends State<UisettingsPage> {
  List<Map<String, dynamic>> sectionsWithKey = [
    {"key": null, "section": null}
  ];

  void displaySnack(String str) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(str)));
      }
    });
  }

  _getItemSize(key) {
    // Using the key to get the RenderBox
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size; // Size of the widget
      print("Item width: ${size.width}, height: ${size.height}");
      return size;
    } else {
      print("RenderBox is null, widget might not be rendered yet.");
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final globalSongData = context.watch<UiSettings>();

    if (globalSongData.currentSongHash != "" &&
        globalSongData.songsDataMap.isNotEmpty &&
        globalSongData.nashvileMappings.isNotEmpty) {
      // Display loaded data when current song is set
      final screenSize = MediaQuery.of(context).size;
      final screenHeight = screenSize.height;
      final appBarHeight =
          AppBar().preferredSize.height; // Default AppBar height
      final availableHeight = screenHeight - appBarHeight;
      final screenWidth = screenSize.width;

      // Section Container generation
      final List<Widget> possibleSections = displaySectionContent(
        globalData: globalSongData,
        uiDisplaySectionData: globalSongData.uiSectionData,
        key: globalSongData.currentKey,
        mappings: globalSongData.nashvileMappings,
        displaySnack: displaySnack,
      );
      for (Widget section in possibleSections) {
        final sectionKey = GlobalKey();
        sectionsWithKey.add({
          "key": sectionKey,
          "section": Container(key: sectionKey, child: section),
        });
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text("LOADED"),
        ),
        body: ListView(children: [
          ListView.builder(itemBuilder: (context, index) {
            return sectionsWithKey[index]["section"];
          }),
          FloatingActionButton(
              onPressed: () {
                for (var section in sectionsWithKey) {
                  print(section);
                  if (section["key"] != null) {
                    _getItemSize(section["key"]);
                  }
                }
              },
              child: const Text("Get Size"))
        ]),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
              "Cant Load Ui Settings, wähle einen Song aus und dann Komme wieder"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
