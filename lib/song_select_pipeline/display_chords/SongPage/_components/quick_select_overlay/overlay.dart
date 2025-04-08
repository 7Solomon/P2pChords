import 'package:flutter/material.dart';
import 'styles.dart';

class QSelectOverlay {
  final List<String> songs;
  String _selectedSong;
  final Function(String) onSongSelected;

  // Track overlay state
  OverlayEntry? _currentOverlay;
  FixedExtentScrollController? _wheelController;
  int _currentSelectedIndex = 0;

  QSelectOverlay({
    required this.songs,
    required String initialSong,
    required this.onSongSelected,
  }) : _selectedSong = initialSong;

  String get selectedSong => _selectedSong;

  void selectSong(String song) {
    if (songs.contains(song)) {
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
        final currentIndex = songs.indexOf(_selectedSong);
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
          final originalIndex = songs.indexOf(_selectedSong);
          final newIndex =
              (originalIndex + indexChange).clamp(0, songs.length - 1);

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
              _currentSelectedIndex < songs.length) {
            selectSong(songs[_currentSelectedIndex]);
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
            // Dark semi-transparent background
            Positioned.fill(
              child: Container(color: Colors.black54),
            ),

            // Centered wheel container
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 250, // 5 items of 50 height
                decoration: QuickSelectStyles.wheelContainer,
                child: Stack(
                  children: [
                    // Selection highlight
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          height: 50,
                          decoration: QuickSelectStyles.selectedItemHighlight,
                        ),
                      ),
                    ),

                    // The wheel picker
                    ListWheelScrollView(
                      controller: _wheelController,
                      itemExtent: 50,
                      diameterRatio: 1.5,
                      onSelectedItemChanged: (index) {
                        _currentSelectedIndex = index;
                        onIndexChanged(index);
                      },
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        songs.length,
                        (index) => Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            songs[index],
                            style: index == _currentSelectedIndex
                                ? QuickSelectStyles.selectedItemText
                                : QuickSelectStyles.itemText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
    if (_wheelController != null && index >= 0 && index < songs.length) {
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
