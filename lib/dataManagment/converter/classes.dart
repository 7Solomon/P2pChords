
class PreliminarySongData {
  final String originalText;
  final List<PreliminarySection> sections;
  final String title;
  final List<String> authors;
  final String key;

  PreliminarySongData({
    required this.originalText,
    required this.sections,
    required this.title,
    this.authors = const [],
    this.key = '',
  });
}

class PreliminarySection {
  String title;
  List<PreliminaryLine> lines;

  PreliminarySection({
    required this.title,
    required this.lines,
  });
}

// Class to represent a line before final processing
class PreliminaryLine {
  String text;
  bool isChordLine;
  bool wasSplit;
  double chordLineCertainty; // Certainty score from 0.0 to 1.0

  PreliminaryLine({
    required this.text,
    required this.isChordLine,
    this.wasSplit = false,
    this.chordLineCertainty = 0.0, // Default to 0
  });
}



///////
/// Section stuff
//////////////////////////// 

class SectionGroup {
  final String title;
  final List<SectionOccurrence> occurrences;
  DuplicateResolution resolution;
  int? specificVersionIndex;

  SectionGroup({
    required this.title,
    required this.occurrences,
    this.resolution = DuplicateResolution.keepAll,
    this.specificVersionIndex,
  });

  bool get hasDuplicates => occurrences.length > 1;
  bool get hasIdenticalContent {
    if (occurrences.length <= 1) return true;
    final normalized = occurrences[0].normalizedContent;
    return occurrences.every((o) => o.normalizedContent == normalized);
  }
}

class SectionOccurrence {
  final int originalIndex;
  final PreliminarySection section;
  final String normalizedContent;

  SectionOccurrence({
    required this.originalIndex,
    required this.section,
    required this.normalizedContent,
  });
}

enum DuplicateResolution {
  keepAll,        // Keep all versions (numbered)
  keepFirst,      // Keep only first occurrence
  keepSpecific,   // Keep specific version (index stored separately)
  mergeIdentical, // Remove identical duplicates, keep one
}