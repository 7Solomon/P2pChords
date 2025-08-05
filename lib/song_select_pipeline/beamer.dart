import 'package:P2pChords/dataManagment/data_class.dart';
import 'package:P2pChords/dataManagment/provider/beamer_ui_provider.dart';
import 'package:P2pChords/dataManagment/provider/current_selection_provider.dart';
import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BeamerPage extends StatefulWidget {
  // Changed to StatefulWidget
  const BeamerPage({
    super.key,
  });

  @override
  State<BeamerPage> createState() => _BeamerPageState();
}

class _BeamerPageState extends State<BeamerPage> {
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
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive,
        overlays: []);
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  _handleBodyTap(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Willst du Aufhören?'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'zurück',
          onPressed: () {
            if (Navigator.canPop(context)) {
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

      // Validate selection when widget builds
      //WidgetsBinding.instance.addPostFrameCallback((_) {
      //  currentSelectionProvider.validateSelection(context);
      //});

      // Safe check for selection
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
