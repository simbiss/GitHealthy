import 'package:flutter/material.dart';
import 'package:marihacks7/service/checkBarcode.dart';

class BarcodeResultPage extends StatelessWidget {
  final String barcodeResult;

  const BarcodeResultPage({super.key, required this.barcodeResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Barcode'),
      ),
      body: Center(
        child: Text(
          OpenFoodFactsAPI.fetchProduct(barcodeResult),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
