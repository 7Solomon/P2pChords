import 'dart:async';
import 'package:P2pChords/state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events

class MetronomeBloc extends Bloc<MetronomeEvent, MetronomeState> {
  Timer? _timer;
  final void Function(int bpm, bool isPlaying, int tickCount)
      onMetronomeChanged;
  int _tickCount = 0;
  DateTime? _lastTickTime;

  MetronomeBloc({required this.onMetronomeChanged})
      : super(MetronomeState(isPlaying: false, bpm: 60, tickCount: 0)) {
    on<StartMetronome>(_onStartMetronome);
    on<StopMetronome>(_onStopMetronome);
    on<UpdateBpm>(_onUpdateBpm);
    on<SyncMetronome>(_onSyncMetronome);
  }

  void _onStartMetronome(StartMetronome event, Emitter<MetronomeState> emit) {
    if (!state.isPlaying) {
      _tickCount = 0;
      _lastTickTime = DateTime.now();
      _startTicking();
      emit(MetronomeState(
          isPlaying: true, bpm: state.bpm, tickCount: _tickCount));
      onMetronomeChanged(state.bpm, true, _tickCount);
    }
  }

  void _onStopMetronome(StopMetronome event, Emitter<MetronomeState> emit) {
    if (state.isPlaying) {
      _timer?.cancel();
      emit(MetronomeState(
          isPlaying: false, bpm: state.bpm, tickCount: _tickCount));
      onMetronomeChanged(state.bpm, false, _tickCount);
    }
  }

  void _onUpdateBpm(UpdateBpm event, Emitter<MetronomeState> emit) {
    emit(MetronomeState(
        isPlaying: state.isPlaying, bpm: event.bpm, tickCount: _tickCount));
    if (state.isPlaying) {
      _startTicking();
    }
    onMetronomeChanged(event.bpm, state.isPlaying, _tickCount);
  }

  void _onSyncMetronome(SyncMetronome event, Emitter<MetronomeState> emit) {
    _tickCount = event.tickCount;
    emit(MetronomeState(
        isPlaying: event.isPlaying, bpm: event.bpm, tickCount: _tickCount));
    if (event.isPlaying) {
      _startTicking();
    } else {
      _timer?.cancel();
    }
  }

  void _startTicking() {
    _timer?.cancel();
    const ticksPerBeat = 4; // Assuming 4 ticks per beat for more precise sync
    final tickInterval =
        Duration(milliseconds: 60000 ~/ (state.bpm * ticksPerBeat));

    _timer = Timer.periodic(tickInterval, (_) {
      _tickCount++;
      if (_tickCount % ticksPerBeat == 0) {
        // This is a main beat
        print('Tick! BPM: ${state.bpm}, Beat: ${_tickCount ~/ ticksPerBeat}');
      }

      emit(MetronomeState(
          isPlaying: true, bpm: state.bpm, tickCount: _tickCount));
      onMetronomeChanged(state.bpm, true, _tickCount);

      // Set _lastTickTime to now and then correct drift
      _lastTickTime = DateTime.now();
      _correctDrift(tickInterval);
    });
  }

  void _correctDrift(Duration expectedInterval) {
    if (_lastTickTime == null) return;

    final now = DateTime.now();
    final actualInterval = now.difference(_lastTickTime!);
    final drift = actualInterval - expectedInterval;

    if (drift.abs() > Duration(milliseconds: 5)) {
      _timer?.cancel();
      _timer = Timer(expectedInterval - drift, () {
        _startTicking();
      });
    }

    _lastTickTime = now;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class MetronomeState {
  final bool isPlaying;
  final int bpm;
  final int tickCount;

  MetronomeState(
      {required this.isPlaying, required this.bpm, required this.tickCount});
}

abstract class MetronomeEvent {}

class StartMetronome extends MetronomeEvent {}

class StopMetronome extends MetronomeEvent {}

class UpdateBpm extends MetronomeEvent {
  final int bpm;
  UpdateBpm(this.bpm);
}

class SyncMetronome extends MetronomeEvent {
  final int bpm;
  final bool isPlaying;
  final int tickCount;
  SyncMetronome(this.bpm, this.isPlaying, this.tickCount);
}

// Extension to NearbyMusicSyncProvider
extension MetronomeSyncExtension on NearbyMusicSyncProvider {
  void sendMetronomeUpdate(int bpm, bool isPlaying, int tickCount) {
    final data = {
      'type': 'metronomeUpdate',
      'content': {
        'bpm': bpm,
        'isPlaying': isPlaying,
        'tickCount': tickCount,
      }
    };
    sendDataToAll(data);
  }

  void handleMetronomeUpdate(Map<String, dynamic> data) {
    if (data['type'] == 'metronomeUpdate') {
      final content = data['content'];
      onMetronomeUpdateReceived?.call(
          content['bpm'], content['isPlaying'], content['tickCount']);
    }
  }
}
