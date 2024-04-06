import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// A mock class to represent a scanned item.
class ScannedItem {
  final String barcode;
  final String date;
  // Préparation pour les futures propriétés
  final String name;
  final String brand;
  final String quality;

  ScannedItem({
    this.barcode = '',
    this.date = '',
    this.name = 'Unknown Name', // Valeurs par défaut pour les futurs champs
    this.brand = 'Unknown Brand',
    this.quality = 'Unknown Quality',
  });

  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      barcode: json['barcode'] ?? 'Unknown Barcode',
      date: json['date'] ?? 'Unknown Date',
      // Les autres champs restent avec des valeurs par défaut pour le moment
    );
  }
}

class DetailedItemPage extends StatelessWidget {
  final ScannedItem item;

  const DetailedItemPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.barcode), // Display barcode as title
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: item.barcode, // Use the same tag as in HistoryPage
              child: Icon(Icons.qr_code, size: 150.0),
            ),
            Text(item.date),
            // Display other item details here
          ],
        ),
      ),
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
          return InkWell(
            onTap: () {
              // Navigate to a detailed page when tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedItemPage(item: item),
                ),
              );
            },
            child: ListTile(
              leading: Hero(
                tag: item.barcode, // Unique tag for the Hero animation
                child: Icon(Icons.qr_code),
              ),
              title: Text(item.barcode),
              subtitle: Text(item.date),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.name),
                  Text(item.brand),
                  Text(item.quality),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: HistoryPage()));
