import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state.dart';
import 'connect_device_screen.dart';

class ChooseSCStatePage extends StatelessWidget {
  beServer(BuildContext context) {
    context.read<GlobalMode>().setUserState(UserState.server);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConnectionPage()),
    );
  }

  beClient(BuildContext context) {
    context.read<GlobalMode>().setUserState(UserState.client);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConnectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CS wahl'),
      ),
      body: Column(
          //mainAxisAlignment: MainAxisAlignment.c,
          children: [
            ElevatedButton(
              onPressed: () => beServer(context),
              child: const Text('Server'),
            ),
            ElevatedButton(
              onPressed: () => beClient(context),
              child: const Text('Client'),
            ),
          ]),
    );
  }
}
