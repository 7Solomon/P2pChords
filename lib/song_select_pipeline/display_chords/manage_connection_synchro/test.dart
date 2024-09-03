import 'package:flutter/material.dart';

class SectionState with ChangeNotifier {
  int _currentSection1 = 0;
  int _currentSection2 = 1;

  int get currentSection1 => _currentSection1;
  int get currentSection2 => _currentSection2;

  void updateSections(int section1, int section2) {
    _currentSection1 = section1;
    _currentSection2 = section2;
    notifyListeners();
    // Also send updates to other devices
    _sendSectionUpdateToPeers(section1, section2);
  }

  void _sendSectionUpdateToPeers(int section1, int section2) {
    // Implement your P2P communication to broadcast the section state
  }

  void receiveSectionUpdateFromPeer(int section1, int section2) {
    _currentSection1 = section1;
    _currentSection2 = section2;
    notifyListeners();
  }
}
