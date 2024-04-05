import 'package:flutter/material.dart';
import 'package:marihacks7/service/scan_service.dart';

class BarcodeScanPage extends StatefulWidget {
  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final ScanService _scanService = ScanService();

  void _startBarcodeScan() async {
    String barcodeResult = await _scanService.scanBarcode();
    if (barcodeResult.isNotEmpty) {
      // Do something with the result, e.g., fetch product details
      print("Scanned Barcode: $barcodeResult");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Barcode"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startBarcodeScan,
          child: Text('Start Scanning'),
        ),
      ),
    );
  }
}
