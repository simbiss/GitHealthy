import 'package:flutter/material.dart';

// A mock class to represent a scanned item.
class ScannedItem {
  final String name;
  final String brand;
  final String quality;
  final String timeScanned;

  ScannedItem(this.name, this.brand, this.quality, this.timeScanned);
}

// A list to simulate a history of scanned items.
final List<ScannedItem> scannedHistory = [
  ScannedItem('Monster Energy Zero Sugar', 'Monster energy', 'Médiocre',
      'À l\'instant'),
  ScannedItem('Stax Salt & Vinegar', 'Lay\'s', 'Mauvais', 'il y a 1 heure'),
];

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Handle info action
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: scannedHistory.length,
        itemBuilder: (context, index) {
          final item = scannedHistory[index];
          return ListTile(
            leading: Image.network(
                'path/to/item/image.png'), // Placeholder for item image
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
