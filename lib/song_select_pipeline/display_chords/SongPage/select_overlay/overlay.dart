import 'package:P2pChords/song_select_pipeline/display_chords/SongPage/select_overlay/style.dart';
import 'package:flutter/material.dart';

class QSelectOverlay {
  final List<String> songHashes;
  final String Function(String) getDisplayName;
  String _selectedSong;
  final Function(String) onSongSelected;

  // Track overlay state
  OverlayEntry? _currentOverlay;
  FixedExtentScrollController? _wheelController;
  int _currentSelectedIndex = 0;

  QSelectOverlay({
    required this.songHashes,
    required String initialSong,
    required this.getDisplayName,
    required this.onSongSelected,
  }) : _selectedSong = initialSong;

  String get selectedSong => _selectedSong;

  void selectSong(String song) {
    if (songHashes.contains(song)) {
      _selectedSong = song;
      onSongSelected(_selectedSong);
    }
  }

  // The main gesture detector that handles long-press to show overlay and drag to select
  Widget buildCHandler({
    required Widget child,
    required BuildContext context,
  }) {
    _context = context;
    return GestureDetector(
      // When long press starts, show the overlay
      onLongPressStart: (details) {
        final currentIndex = songHashes.indexOf(_selectedSong);
        _showOverlayAtPosition(
          details.globalPosition,
          currentIndex >= 0 ? currentIndex : 0,
          (idx) => _currentSelectedIndex = idx,
        );
      },
      behavior: HitTestBehavior.deferToChild,

      // As user drags finger while long pressing, update selection
      onLongPressMoveUpdate: (details) {
        if (_currentOverlay != null) {
          // Get vertical movement
          final verticalDelta = details.offsetFromOrigin.dy;

          // Convert movement to index change (negative is up, positive is down)
          const sensitivity = 5.0; // Adjust this for sensitivity
          int indexChange = -(verticalDelta / sensitivity).round();

          // Calculate new index by adding change to original selected index
          final originalIndex = songHashes.indexOf(_selectedSong);
          final newIndex =
              (originalIndex + indexChange).clamp(0, songHashes.length - 1);

          // Update the wheel position if changed
          if (newIndex != _currentSelectedIndex) {
            _updateOverlaySelection(newIndex);
          }
        }
      },

      // When long press ends, finalize selection and hide overlay
      onLongPressEnd: (details) {
        if (_currentOverlay != null) {
          // Select the current item
          if (_currentSelectedIndex >= 0 &&
              _currentSelectedIndex < songHashes.length) {
            selectSong(songHashes[_currentSelectedIndex]);
          }
          _hideOverlay();
        }
      },

      child: child,
    );
  }

  // Store the context when building the gesture detector
  BuildContext? _context;

  void _showOverlayAtPosition(
      Offset position, int initialIndex, Function(int) onIndexChanged) {
    // Create wheel controller
    _wheelController = FixedExtentScrollController(initialItem: initialIndex);
    _currentSelectedIndex = initialIndex;

    // Use the overlay from the current overlay state
    final overlayState = Overlay.of(_context!);

    // Create the overlay entry with the wheel
    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Lighter, more subtle background with blur effect simulation
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.85),
              ),
            ),

            // Centered wheel container with header
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Text(
                      'SELECT SONG',
                      style: QuickSelectStyles.headerText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Main wheel container
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 280, // 5.5 items visible
                    decoration: QuickSelectStyles.wheelContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Stack(
                      children: [
                        // Fade effects at top and bottom
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Selection highlight with indicator
                        Positioned.fill(
                          child: Center(
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                QuickSelectStyles.buildSelectionIndicator(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: QuickSelectStyles.selectedItemHighlight,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),

                        // The wheel picker
                        ListWheelScrollView(
                          controller: _wheelController,
                          itemExtent: 56,
                          diameterRatio: 1.8,
                          magnification: 1.05,
                          useMagnifier: true,
                          onSelectedItemChanged: (index) {
                            _currentSelectedIndex = index;
                            onIndexChanged(index);
                          },
                          physics: const NeverScrollableScrollPhysics(),
                          children: List.generate(
                            songHashes.length,
                            (index) => Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 44, right: 24),
                              child: Text(
                                getDisplayName(songHashes[index]),
                                style: index == _currentSelectedIndex
                                    ? QuickSelectStyles.selectedItemText
                                    : QuickSelectStyles.itemText,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Footer hint
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Release to select',
                      style: QuickSelectStyles.headerText.copyWith(
                        fontSize: 12,
                        color: QuickSelectStyles.lightText.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Insert the overlay
    overlayState.insert(_currentOverlay!);
  }

  // Updates the selected item in the overlay
  void _updateOverlaySelection(int index) {
    if (_wheelController != null && index >= 0 && index < songHashes.length) {
      // Update controller position
      _wheelController!.animateToItem(
        index,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );

      // Update tracking variable
      _currentSelectedIndex = index;
    }
  }

  // Hides and cleans up the overlay
  void _hideOverlay() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }

    if (_wheelController != null) {
      _wheelController!.dispose();
      _wheelController = null;
    }
  }
}