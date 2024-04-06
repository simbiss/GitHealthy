import 'package:flutter/material.dart';

class BarcodeResultPage extends StatelessWidget {
  final String barcodeResult;

  const BarcodeResultPage({Key? key, required this.barcodeResult})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanned Barcode'),
      ),
      body: Center(
        child: Text(
          barcodeResult,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
