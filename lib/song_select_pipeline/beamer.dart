import 'package:P2pChords/dataManagment/dataClass.dart';
import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BeamerPage extends StatelessWidget {
  const BeamerPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Set system UI to be transparent against black background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ));

    Widget beamerDisplay(SongSection section) {
      return Column(
          children: section.lines.map((line) {
        return Text(
          line.lyrics,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 22,
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
          dataLoaderProvider.songs != null &&
          dataLoaderProvider.songs!.isNotEmpty &&
          dataLoaderProvider.songs!
              .containsKey(currentSelectionProvider.currentSongHash!);
    }

    return Consumer2<CurrentSelectionProvider, DataLoadeProvider>(
        builder: (context, currentselection, dataloader, _) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  selectionIsInitiated()
                      ? beamerDisplay(
                          dataloader.songs![currentselection.currentSongHash!]!
                              .sections[currentselection.currentSectionIndex!],
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
      );
    });
  }
}
