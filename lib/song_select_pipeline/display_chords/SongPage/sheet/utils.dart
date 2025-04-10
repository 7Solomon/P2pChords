import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

class TapFriendlyScrollPhysics extends ClampingScrollPhysics {
  const TapFriendlyScrollPhysics({super.parent});

  @override
  TapFriendlyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TapFriendlyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold =>
      100.0; // Higher threshold for drag vs. tap
}

// Simplified section info class to reduce redundancy
class SectionInfo {
  final Song song;
  final SongSection section;
  final int songIndex;
  final int sectionIndex;
  final bool isFirstSectionOfSong;
  final bool isLastSectionOfSong;

  SectionInfo({
    required this.song,
    required this.section,
    required this.songIndex,
    required this.sectionIndex,
    required this.isFirstSectionOfSong,
    required this.isLastSectionOfSong,
  });
}
