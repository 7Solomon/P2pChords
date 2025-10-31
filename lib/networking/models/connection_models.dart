import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Represents a connected spoke (client) on the hub side
class SpokeConnection {
  final String id;
  final String name;
  final WebSocketChannel channel;
  final DateTime connectedAt;
  DateTime lastPing;
  Timer? healthCheckTimer;

  SpokeConnection({
    required this.id,
    required this.name,
    required this.channel,
    DateTime? connectedAt,
    DateTime? lastPing,
  })  : connectedAt = connectedAt ?? DateTime.now(),
        lastPing = lastPing ?? DateTime.now();

  bool get isHealthy {
    final timeSinceLastPing = DateTime.now().difference(lastPing);
    return timeSinceLastPing.inSeconds < 30; // 30 second timeout
  }

  void updatePing() {
    lastPing = DateTime.now();
  }

  Future<void> send(Map<String, dynamic> data) async {
    try {
      channel.sink.add(data);
    } catch (e) {
      print('Error sending to spoke $id: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    healthCheckTimer?.cancel();
    await channel.sink.close();
  }
}

/// Represents a discovered hub from the spoke side
class DiscoveredHub {
  final String id;
  final String name;
  final String host;
  final int port;
  final DateTime discoveredAt;
  bool isValidated;

  DiscoveredHub({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    DateTime? discoveredAt,
    this.isValidated = false,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get address => '$host:$port';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredHub &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}

/// Message protocol between hub and spokes
enum MessageType {
  handshake,
  handshakeAck,
  ping,
  pong,
  stateUpdate,
  songData,
  metronomeUpdate,
  disconnect,
  error,

  songDataRequest,      // NEW

}

class HubMessage {
  final MessageType type;
  final Map<String, dynamic> payload;
  final String? senderId;
  final DateTime timestamp;

  HubMessage({
    required this.type,
    required this.payload,
    this.senderId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'payload': payload,
        'senderId': senderId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HubMessage.fromJson(Map<String, dynamic> json) {
    return HubMessage(
      type: MessageType.values.byName(json['type']),
      payload: json['payload'] as Map<String, dynamic>,
      senderId: json['senderId'] as String?,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}