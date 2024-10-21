import 'package:P2pChords/metronome/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlinkingCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetronomeBloc, MetronomeState>(
      builder: (context, state) {
        bool isVisible = state.isPlaying ? state.tickCount % 4 == 0 : true;
        return Positioned(
          top: 16,
          right: 16,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
