import 'dart:convert';

import 'package:P2pChords/navigator.dart';
import 'package:flutter/material.dart';

Map<String, dynamic> compareJson(String? jsonString1, String jsonString2) {
  // Handle null or empty first string
  if (jsonString1 == null || jsonString1.isEmpty) {
    return {'Gesamter Inhalt': 'Neuer Song'};
  }

  var json1 = jsonDecode(jsonString1);
  var json2 = jsonDecode(jsonString2);

  Map<String, dynamic> differences = {};
  findDifferences(json1, json2, path: [], differenceMap: differences);

  return differences;
}

void findDifferences(dynamic obj1, dynamic obj2,
    {required List<String> path, required Map<String, dynamic> differenceMap}) {
  if (obj1 == null && obj2 != null) {
    addDifference(
        differenceMap, path, 'Neuer Wert', 'Wert wurde hinzugefügt: $obj2');
    return;
  }

  if (obj1.runtimeType != obj2.runtimeType) {
    addDifference(differenceMap, path, 'Typunterschied',
        '${obj1.runtimeType} vs ${obj2.runtimeType}');
    return;
  }

  if (obj1 is Map) {
    // Check for keys in obj1 not in obj2
    for (var key in obj1.keys) {
      if (!obj2.containsKey(key)) {
        addDifference(differenceMap, path, 'Fehlender Schlüssel',
            "Schlüssel '$key' fehlt in zweitem JSON");
        continue;
      }
      findDifferences(obj1[key], obj2[key],
          path: [...path, key], differenceMap: differenceMap);
    }

    // Check for keys in obj2 not in obj1
    for (var key in obj2.keys) {
      if (!obj1.containsKey(key)) {
        addDifference(differenceMap, path, 'Zusätzlicher Schlüssel',
            "Schlüssel '$key' fehlt in erstem JSON");
      }
    }
  } else if (obj1 is List) {
    // Compare lists
    int minLength = obj1.length < obj2.length ? obj1.length : obj2.length;
    for (int i = 0; i < minLength; i++) {
      findDifferences(obj1[i], obj2[i],
          path: [...path, '[${i}]'], differenceMap: differenceMap);
    }

    if (obj1.length > obj2.length) {
      addDifference(differenceMap, path, 'Zusätzliche Elemente',
          "Zusätzliche Elemente im ersten JSON-Array: ${obj1.sublist(obj2.length)}");
    } else if (obj2.length > obj1.length) {
      addDifference(differenceMap, path, 'Zusätzliche Elemente',
          "Zusätzliche Elemente im zweiten JSON-Array: ${obj2.sublist(obj1.length)}");
    }
  } else {
    // Compare primitive values
    if (obj1 != obj2) {
      addDifference(differenceMap, path, 'Wertunterschied', 'Hier die Werte',
          obj1: obj1.toString(), obj2: obj2.toString());
    }
  }
}

void addDifference(Map<String, dynamic> differenceMap, List<String> path,
    String type, String description,
    {String obj1 = 'null', String obj2 = 'null'}) {
  String pathKey = path.isEmpty ? 'Wurzel' : path.join(' > ');
  //differenceMap[pathKey] = {'typ': type, 'beschreibung': description};
  if (obj1 != 'null' && obj2 != 'null') {
    differenceMap[pathKey] = {
      'typ': type,
      'beschreibung': description,
      'obj1': obj1,
      'obj2': obj2
    };
  } else {
    differenceMap[pathKey] = {'typ': type, 'beschreibung': description};
  }
}

Future<bool> openDiffrenceWindow(String msg,
    {Map<String, dynamic>? differences}) async {
  return await showDialog(
        context: NavigationService.navigatorKey.currentState!.context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bestätige bitte'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg),
                  if (differences != null && differences.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Gefundene Unterschiede:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...differences.entries
                        .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.value.containsKey('obj1') &&
                                    entry.value.containsKey('obj2')) ...[
                                  Text(
                                    '${entry.value['typ']}',
                                    style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Das ist das vorhandene',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                border: Border.all(
                                                    color: Colors.blue[100]!),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                entry.value['obj1'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Das wäre das Neue',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red[800],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                border: Border.all(
                                                    color: Colors.red[100]!),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                entry.value['obj2'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Text(
                                    '${entry.value['typ']} \n ${entry.value['beschreibung']}',
                                    style: TextStyle(
                                        color: Colors.red[700], fontSize: 12),
                                  ),
                                ]
                              ],
                            )))
                        .toList(),
                  ]
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Nein'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Ja'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      ) ??
      false;
}
