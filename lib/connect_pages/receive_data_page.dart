import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import '../state.dart';

class ReceivingPage extends StatefulWidget {
  @override
  _ReceivingPageState createState() => _ReceivingPageState();
}

class _ReceivingPageState extends State<ReceivingPage> {
  List<String> _receivedMessages = [];
  GlobalUserIds? _globalUserIds;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);
    _globalUserIds?.addListener(_handleIncomingMessages);
  }

  void _setupMessageListener() {
    final globalUserIds = Provider.of<GlobalUserIds>(context, listen: false);
    globalUserIds.addListener(_handleIncomingMessages);
  }

  void _handleIncomingMessages() {
    // This method will be called whenever the GlobalUserIds state changes
    // You can implement logic here to check for new messages and update the UI
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _globalUserIds?.removeListener(_handleIncomingMessages);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Receive Data')),
      body: Consumer<GlobalUserIds>(
        builder: (context, globalUserIds, child) {
          return ListView.builder(
            itemCount: globalUserIds.receivedMessages.length,
            itemBuilder: (context, index) {
              final message = globalUserIds.receivedMessages[index];
              return ListTile(
                title: Text(message),
                leading: Icon(Icons.message),
              );
            },
          );
        },
      ),
    );
  }
}
