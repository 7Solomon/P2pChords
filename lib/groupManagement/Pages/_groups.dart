//import 'package:P2pChords/dataManagment/Pages/edit/page.dart';
//import 'package:P2pChords/dataManagment/Pages/load_json_page.dart';
//import 'package:P2pChords/dataManagment/data_base/page.dart';
//import 'package:P2pChords/dataManagment/data_class.dart';
//import 'package:P2pChords/dataManagment/provider/data_loade_provider.dart';
//import 'package:P2pChords/styling/SpeedDial.dart';
//import 'package:P2pChords/utils/notification_service.dart';
//import 'package:flutter/material.dart';
//import 'package:P2pChords/dataManagment/storageManager.dart';
//import 'package:P2pChords/groupManagement/functions.dart';
//import 'package:P2pChords/styling/Tiles.dart';
//import 'package:flutter_speed_dial/flutter_speed_dial.dart';
//import 'package:provider/provider.dart';

//class ManageGroupPage extends StatefulWidget {
//  const ManageGroupPage({super.key});
//
//  @override
//  _ManageGroupPageState createState() => _ManageGroupPageState();
//}
//
//class _ManageGroupPageState extends State<ManageGroupPage> {
//  @override
//  void initState() {
//    super.initState();
//    WidgetsBinding.instance.addPostFrameCallback((_) {
//      // hoffe me mal das brauchen wir nicht mehr
//      //Provider.of<DataLoadeProvider>(context, listen: false).refreshData();
//    });
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Gruppen Übersicht'),
//      ),
//      body: Consumer<DataLoadeProvider>(
//        builder: (context, dataProvider, child) {
//          if (dataProvider.isLoading) {
//            return const Center(child: CircularProgressIndicator());
//          }
//          final groups = dataProvider.groups;
//          if (groups.isEmpty) {
//            return const Center(child: Text('Keine Gruppen vorhanden'));
//          }
//          return ListView(
//            children: groups.keys.map((group) {
//              return CDissmissible.deleteAndAction(
//                key: Key(group),
//                deleteIcon: Icons.delete,
//                actionIcon: Icons.download,
//                deleteConfirmation: () =>
//                    CDissmissible.showDeleteConfirmationDialog(context),
//                confirmActionDismiss: () async {
//                  SongData songsdata = dataProvider.getSongData(group);
//                  await exportGroupsData(songsdata);
//                },
//                confirmDeleteDismiss: () async {
//                  await dataProvider.removeGroup(group);
//                  setState(() {});
//                },
//                child: CListTile(
//                  title: group,
//                  context: context,
//                  icon: Icons.file_copy,
//                  subtitle: 'Klicke um die Songs der Gruppe anzusehen',
//                  onTap: () {
//                    Navigator.push(
//                      context,
//                      MaterialPageRoute(
//                        builder: (context) => GroupSongsPage(group: group),
//                      ),
//                    );
//                  },
//                ),
//              );
//            }).toList(),
//          );
//        },
//      ),
//    );
//  }
//}
