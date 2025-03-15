import 'dart:convert';

import 'package:flutter/material.dart';

//class MessagingHandler {
//  //displaySnack(String str) {
//  //  WidgetsBinding.instance.addPostFrameCallback((_) {
//  //    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(str)));
//  //  });
//  //}
//
//  void handleIncomingMessage(String message) {
//    try {
//      Map<String, dynamic> data = json.decode(message.trim());
//      displaySnack("Received message: ${data['type']}");
//
//      switch (data['type']) {
//        case 'update':
//          Map<String, dynamic> updateContent =
//              data['content'] as Map<String, dynamic>;
//          _currentSectionProvider.fromJson(updateContent);
//        case 'songData':
//          SongData songData = SongData.fromMap(data['content']['songData']);
//          MultiJsonStorage.saveSongsData(songData);
//          break;
//        case 'metronomeUpdate':
//          //handleMetronomeUpdate(data);
//          break;
//      }
//      notifyListeners();
//    } catch (e) {
//      _displaySnack('Error handling incoming message: $e');
//    }
//  }
//}
//
//class MessagingSender {}
