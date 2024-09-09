import 'package:P2pChords/connect/pages/clientPage.dart';
import 'package:P2pChords/connect/pages/serverPage.dart';
import 'package:P2pChords/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';

class ChooseSCStatePage extends StatelessWidget {
  const ChooseSCStatePage({super.key});

  void _setUserStateAndNavigate(BuildContext context, UserState state) {
    context.read<GlobalMode>().setUserState(state);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (state == UserState.server) {
            return const ServerPage(); // Navigate to ServerPage
          }
          if (state == UserState.client) {
            return const ClientPage(); // Navigate to ClientPage
          } else {
            //displayS
            print('NOne');
            return MainPage();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[300]!, Colors.purple[300]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Wähle deine Rolle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () =>
                      _setUserStateAndNavigate(context, UserState.server),
                  child: Text('Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      _setUserStateAndNavigate(context, UserState.client),
                  child: Text('Client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[700],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
