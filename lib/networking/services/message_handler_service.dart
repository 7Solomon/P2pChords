import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:P2pChords/dataManagment/data_class.dart';

class MessageHandlerService {
  // Singleton pattern
  static final MessageHandlerService _instance =
      MessageHandlerService._internal();
  factory MessageHandlerService() => _instance;

  // Callbacks for different message types
  late Function(Map<String, dynamic>) onUpdateMessage;
  late Function(SongData) onSongDataMessage;
  late Function(Map<String, dynamic>) onMetronomeUpdate;

  // Notification callback for important events
  Function(String)? onNotification;

  MessageHandlerService._internal();

  void _notify(String message) {
    if (onNotification != null) {
      onNotification!(message);
    }
  }

  // Handle incoming payload from the connection service
  void handlePayload(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      String message = String.fromCharCodes(payload.bytes!);
      handleIncomingMessage(message);
    }
  }

  // Process incoming message string
  void handleIncomingMessage(String message) {
    try {
      Map<String, dynamic> data = json.decode(message.trim());
      _notify("Received message: ${data['type']}");

      switch (data['type']) {
        //case 'connection_established':
        //  _notify('Connection established with ${data['content']['name']}');
        //  break;  // Wird doxh nicht gebraucht
        case 'update':
          Map<String, dynamic> updateContent =
              data['content'] as Map<String, dynamic>;
          onUpdateMessage(updateContent);
          break;

        case 'songData':
          SongData songData = SongData.fromMap(data['content']['songData']);
          onSongDataMessage(songData);

          break;

        case 'metronomeUpdate':
          Map<String, dynamic> metronomeContent =
              data['content'] as Map<String, dynamic>;
          onMetronomeUpdate(metronomeContent);

          break;
      }
    } catch (e) {
      print('Error handling incoming message: $e');
      _notify('Error handling incoming message: $e');
    }
  }
}
