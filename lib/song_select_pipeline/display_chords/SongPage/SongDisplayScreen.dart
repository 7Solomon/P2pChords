import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/displayFunctions.dart';
import 'package:P2pChords/state.dart';
import 'package:P2pChords/uiSettings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongDisplayScreen extends StatefulWidget {
  final globalData;
  final mappings;
  final void Function(String) displaySnack;
  const SongDisplayScreen({
    Key? key,
    required this.globalData,
    required this.mappings,
    required this.displaySnack,
  }) : super(key: key);

  @override
  _SongDisplayScreenState createState() => _SongDisplayScreenState();
}

class _SongDisplayScreenState extends State<SongDisplayScreen> {
  late UiSettings globalSongData; // Store provider instance here
  // remove !!!! sectionWidgets
  //final sectionWidgets = [];
  @override
  void initState() {
    super.initState();
    globalSongData = Provider.of<UiSettings>(context, listen: false);
  }

  void _handleTap(BuildContext context, Offset tapPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final double height = box.size.height;
    final bool isTopHalf = tapPosition.dy < height / 2;
    final bool isRightQuarter = tapPosition.dx > box.size.width * 0.75;

    if (isTopHalf) {
      globalSongData..updateListOfDisplaySectionsUp();
    } else {
      globalSongData..updateListOfDisplaySectionsDown();
    }
  }

  //void onStartReached() {
  //final List<Map<String, String>> allSongs =
  //    allGroups?[songSyncProvider.currentGroup] ?? [];
//
  //for (int i = 1; i < allSongs.length; i++) {
  //  if (allSongs[i]['hash'] == songSyncProvider.currentSongHash) {
  //    songSyncProvider.updateSongAndSection(
  //        allSongs[i - 1]['hash']!, [1, 2], 2);
  //    break;
  //  }
  //}
  //}

  //void onEndReached() {
  //final List<Map<String, String>> allSongs =
  //    allGroups?[songSyncProvider.currentGroup] ?? [];
//
  //for (int i = 0; i < allSongs.length - 1; i++) {
  //  if (allSongs[i]['hash'] == songSyncProvider.currentSongHash) {
  //    songSyncProvider.updateSongAndSection(
  //        allSongs[i + 1]['hash']!, [0, 1], 2);
  //    break;
  //  }
  //}
  //}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        _handleTap(context, details.localPosition);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displaySectionContent(
            globalData: widget
                .globalData, // was widget.globalData.groupSongMap before, viellecicht so schöner
            uiDisplaySectionData: widget.globalData.UiSectionData,
            key: widget.globalData.currentKey,
            mappings: widget.mappings,
            displaySnack: widget.displaySnack),
      ),
    );
  }
}
