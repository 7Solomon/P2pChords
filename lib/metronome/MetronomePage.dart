import 'package:P2pChords/customeWidgets/MetronomeBlinkWidget.dart';
import 'package:P2pChords/metronome/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//class MetronomePage extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text('Metronome')),
//      body: Stack(
//        children: [
//          // Your existing page content here
//          Center(
//            child: BlocBuilder<MetronomeBloc, MetronomeState>(
//              builder: (context, state) {
//                return Column(
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: [
//                    Text('BPM: ${state.bpm}'),
//                    Text('Playing: ${state.isPlaying}'),
//                    ElevatedButton(
//                      onPressed: () => context.read<MetronomeBloc>().add(
//                          state.isPlaying ? StopMetronome() : StartMetronome()),
//                      child: Text(state.isPlaying ? 'Stop' : 'Start'),
//                    ),
//                    Slider(
//                      value: state.bpm.toDouble(),
//                      min: 40,
//                      max: 208,
//                      divisions: 168,
//                      onChanged: (value) => context
//                          .read<MetronomeBloc>()
//                          .add(UpdateBpm(value.round())),
//                    ),
//                  ],
//                );
//              },
//            ),
//          ),
//          BlinkingCircle(),
//        ],
//      ),
//    );
//  }
//}
