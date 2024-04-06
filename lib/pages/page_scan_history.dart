import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// A mock class to represent a scanned item.
class ScannedItem {
  final String name;
  final String brand;
  final String quality;
  final String timeScanned;

  ScannedItem(this.name, this.brand, this.quality, this.timeScanned);

  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      json['name'],
      json['brand'],
      json['quality'],
      json['timeScanned'],
    );
  }
}

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ScannedItem> scannedHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchScannedItems();
  }

  Future<void> _fetchScannedItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('userName');

    if (username == null) {
      print("Username not found");
      return;
    }

    final Uri uri = Uri.parse('http://v34l.com:8080/api/$username/barcodes');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedItems = json.decode(response.body);
        setState(() {
          scannedHistory = fetchedItems
              .map((dynamic item) => ScannedItem.fromJson(item))
              .toList();
        });
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique'),
      ),
      body: ListView.builder(
        itemCount: scannedHistory.length,
        itemBuilder: (context, index) {
          final item = scannedHistory[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text(item.brand),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.quality),
                Text(item.timeScanned),
              ],
            ),
          );
        },
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: HistoryPage()));
