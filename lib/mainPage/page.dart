import 'package:P2pChords/dataManagment/dataGetter.dart';
import 'package:P2pChords/mainPage/buildWidgets.dart';
import 'package:P2pChords/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/UiSettings/page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _loadedProvider = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //final connectionProvider =
      //    Provider.of<ConnectionProvider>(context, listen: false);
      setState(() {
        _loadedProvider = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedProvider) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initializing...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Consumer3<ConnectionProvider, CurrentSelectionProvider,
        DataLoadeProvider>(
      builder:
          (context, connectionProvider, currentSection, dataLoader, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('P2P Chords'),
            actions: [
              // Status indicator
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: buildConnectionStatusChip(context, connectionProvider),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: buildMainContent(
                  context, connectionProvider, currentSection, dataLoader),
            ),
          ),
        );
      },
    );
  }
}
