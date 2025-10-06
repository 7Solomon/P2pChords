import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/beamer_ui_provider.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';

class BeamerPage extends StatefulWidget {
  const BeamerPage({
    super.key,
  });

  @override
  State<BeamerPage> createState() => _BeamerPageState();
}

class _BeamerPageState extends State<BeamerPage> {
  bool _wasFullScreen = false;

  @override
  void initState() {
    super.initState();
    _enterFullScreen();
  }

  @override
  void dispose() {
    _exitFullScreen();
    super.dispose();
  }

  Future<void> _enterFullScreen() async {
    // Mobile fullscreen
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
      overlays: [],
    );

    // Desktop fullscreen (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Ensure window manager is ready
      await windowManager.ensureInitialized();
      
      _wasFullScreen = await windowManager.isFullScreen();
      
      // Hide title bar and set fullscreen
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
      
      // Force focus on the window
      await windowManager.focus();
      await windowManager.show();
    }
  }

  Future<void> _exitFullScreen() async {
    // Mobile
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    // Desktop - only exit fullscreen if it wasn't already fullscreen
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (!_wasFullScreen) {
        await windowManager.setFullScreen(false);
        // Restore title bar
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      }
    }
  }

  _handleBodyTap(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Willst du Aufhören?'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'zurück',
          onPressed: () async {
            // Exit fullscreen before popping
            await _exitFullScreen();
            
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ));

    Widget beamerDisplay(SongSection section) {
      final currentSelectionProvider =
          Provider.of<CurrentSelectionProvider>(context);
      final dataLoaderProvider = Provider.of<DataLoadeProvider>(context);
      final uiProvider = Provider.of<BeamerUiProvider>(context);

      bool selectionIsValid =
          currentSelectionProvider.currentSongHash != null &&
              currentSelectionProvider.currentSectionIndex != null &&
              dataLoaderProvider.songs
                  .containsKey(currentSelectionProvider.currentSongHash!);

      if (!selectionIsValid) {
        return Text(
          'Warte auf die Auswahl eines Liedes durch den Server',
          style: TextStyle(
              color: Colors.white, fontSize: uiProvider.uiVariables.fontSize),
        );
      }

      return Column(
          children: section.lines.map((line) {
        return Text(
          line.lyrics,
          style: TextStyle(
            fontFamily: uiProvider.uiVariables.fontFamily,
            fontSize: uiProvider.uiVariables.fontSize,
            color: Colors.white,
            height: 1.6,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        );
      }).toList());
    }

    bool selectionIsInitiated() {
      final currentSelectionProvider = context.read<CurrentSelectionProvider>();
      final dataLoaderProvider = context.read<DataLoadeProvider>();
      return currentSelectionProvider.currentSongHash != null &&
          currentSelectionProvider.currentSectionIndex != null &&
          dataLoaderProvider.songs.isNotEmpty &&
          dataLoaderProvider.songs
              .containsKey(currentSelectionProvider.currentSongHash!);
    }

    return Consumer2<CurrentSelectionProvider, DataLoadeProvider>(
        builder: (context, currentselection, dataloader, _) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onDoubleTap: () => _handleBodyTap(context),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    selectionIsInitiated()
                        ? beamerDisplay(
                            dataloader.songs[currentselection.currentSongHash!]!
                                    .sections[
                                currentselection.currentSectionIndex!],
                          )
                        : const Text(
                            'Warte auf die Auswahl eines Liedes durch den Server',
                            style: TextStyle(
                              fontFamily: 'Courier New',
                              fontSize: 32,
                              color: Colors.white,
                              height: 1.6,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}