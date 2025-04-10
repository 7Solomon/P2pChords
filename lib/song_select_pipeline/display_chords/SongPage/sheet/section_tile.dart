import 'package:P2pChords/UiSettings/data_class.dart';
import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:flutter/material.dart';

class SectionTile extends StatelessWidget {
  final Song song;
  final SongSection section;
  final int songIndex;
  final int sectionIndex;
  final bool isCurrentSection;
  final bool isCurrentSong;
  final bool isFirstSectionOfSong;
  final bool isLastSectionOfSong;
  final UiVariables uiVariables;
  final Widget Function(LyricLine) buildLine;

  const SectionTile({
    super.key,
    required this.song,
    required this.section,
    required this.songIndex,
    required this.sectionIndex,
    required this.isCurrentSection,
    required this.isCurrentSong,
    required this.isFirstSectionOfSong,
    required this.isLastSectionOfSong,
    required this.uiVariables,
    required this.buildLine,
  });

  @override
  Widget build(BuildContext context) {
    bool hasNextSection = !isLastSectionOfSong;

    // Build section content with conditional title
    Widget sectionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show song title ONLY on the first displayed section of each song
        // TITEL
        if (isFirstSectionOfSong)
          Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              song.header.name,
              style: TextStyle(
                fontSize: uiVariables.fontSize.value + 2,
                fontWeight: FontWeight.bold,
                color: isCurrentSong ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        // SectionIndex
        Container(
          padding: const EdgeInsets.only(bottom: 4.0),
          alignment: Alignment.topRight,
          child: Text(
            "${sectionIndex + 1} / ${song.sections.length}",
            style: TextStyle(
              fontSize: uiVariables.fontSize.value - 2,
              fontStyle: FontStyle.italic,
              color: isCurrentSong
                  ? Colors.blue.withOpacity(0.7)
                  : Colors.grey.withOpacity(0.7),
            ),
          ),
        ),
        // The actual section content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title.toUpperCase(),
              style: TextStyle(
                fontSize: uiVariables.fontSize.value + 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...section.lines.map((line) => buildLine(line)),
            const SizedBox(height: 24),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentSection
              ? Colors.blue
              : isCurrentSong
                  ? Colors.grey.shade400
                  : Colors.grey.shade200,
          width: isCurrentSection ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        // Add directional gradient
        gradient: LinearGradient(
          // Direction indicator - top to bottom if first section, otherwise
          // bottom to right for last section of song, or right for middle sections
          begin:
              isFirstSectionOfSong ? Alignment.topCenter : Alignment.centerLeft,
          end: hasNextSection ? Alignment.bottomRight : Alignment.centerRight,
          colors: [
            isCurrentSong
                ? Colors.blue.withOpacity(0.05)
                : Colors.grey.withOpacity(0.03),
            Colors.transparent,
            isCurrentSong && hasNextSection
                ? Colors.blue.withOpacity(0.1)
                : hasNextSection
                    ? Colors.grey.withOpacity(0.05)
                    : Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      padding:
          isCurrentSection ? const EdgeInsets.all(8) : const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add a colored tag at the top if not first section
          if (!isFirstSectionOfSong)
            Container(
              height: 4,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isCurrentSong
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Direction indicator for next section
          //if (hasNextSection && !isLastSectionOfSong)
          //  Align(
          //    alignment: Alignment.bottomRight,
          //    child: Icon(
          //      Icons.arrow_downward,
          //      size: 14,
          //      color: isCurrentSong
          //          ? Colors.blue.withOpacity(0.3)
          //          : Colors.grey.withOpacity(0.2),
          //    ),
          //  ),
          sectionContent,
        ],
      ),
    );
  }
}
