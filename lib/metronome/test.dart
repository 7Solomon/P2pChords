import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nearby_connections/nearby_connections.dart';

class P2PMetronome extends StatefulWidget {
  @override
  _P2PMetronomeState createState() => _P2PMetronomeState();
}

class _P2PMetronomeState extends State<P2PMetronome> {
  int _bpm = 120;
  bool _isPlaying = false;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isHost = false;
  String? _connectedDeviceId;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    await _audioPlayer.setSource(AssetSource('metronome_click.mp3'));
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      setState(() {
        _connectedDeviceId = id;
        _isHost = true;
      });
    }
  }

  void _onDisconnected(String id) {
    setState(() {
      _connectedDeviceId = null;
      _isHost = false;
    });
  }

  void _onEndpointFound(String id, String userName, String serviceId) {
    Nearby().requestConnection(
      "Device ${DateTime.now().millisecondsSinceEpoch}",
      id,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  void _onEndpointLost(String id) {
    // Handle endpoint lost
  }

  void _onPayloadReceived(String id, Payload payload) {
    String message = String.fromCharCodes(payload.bytes!);
    Map<String, dynamic> data = jsonDecode(message);
    if (data['type'] == 'sync') {
      _syncMetronome(data['bpm'], data['timestamp']);
    }
  }

  void _onPayloadTransferUpdate(String id, PayloadTransferUpdate update) {
    // Handle payload transfer updates if needed
  }

  void _toggleMetronome() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startMetronome();
        if (_isHost && _connectedDeviceId != null) {
          _sendSyncMessage();
        }
      } else {
        _stopMetronome();
      }
    });
  }

  void _startMetronome() {
    final interval = Duration(milliseconds: (60000 / _bpm).round());
    _timer = Timer.periodic(interval, (timer) {
      _audioPlayer.resume();
    });
  }

  void _stopMetronome() {
    _timer?.cancel();
    _audioPlayer.stop();
  }

  void _changeBPM(int newBPM) {
    setState(() {
      _bpm = newBPM;
      if (_isPlaying) {
        _stopMetronome();
        _startMetronome();
        if (_isHost && _connectedDeviceId != null) {
          _sendSyncMessage();
        }
      }
    });
  }

  void _sendSyncMessage() {
    if (_connectedDeviceId != null) {
      Map<String, dynamic> syncData = {
        'type': 'sync',
        'bpm': _bpm,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      Nearby().sendBytesPayload(_connectedDeviceId!,
          Uint8List.fromList(jsonEncode(syncData).codeUnits));
    }
  }

  void _syncMetronome(int bpm, int timestamp) {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int timeDifference = currentTime - timestamp;

    setState(() {
      _bpm = bpm;
      _isPlaying = true;
    });

    _stopMetronome();

    // Calculate the delay for the next beat
    int beatInterval = (60000 / _bpm).round();
    int delay = beatInterval - (timeDifference % beatInterval);

    // Start the metronome after the calculated delay
    Future.delayed(Duration(milliseconds: delay), () {
      _startMetronome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$_bpm BPM',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _changeBPM(_bpm - 1),
              child: Icon(Icons.remove),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _toggleMetronome,
              child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: () => _changeBPM(_bpm + 1),
              child: Icon(Icons.add),
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(_connectedDeviceId != null
            ? 'Connected to: $_connectedDeviceId'
            : 'Not connected'),
        Text(_isHost ? 'Host' : 'Client'),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    Nearby().stopAllEndpoints();
    super.dispose();
  }
}
