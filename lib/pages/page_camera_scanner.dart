import 'package:flutter/material.dart';
import 'package:marihacks7/service/scan_service.dart';
import 'package:marihacks7/pages/page_barcode_result.dart';

class BarcodeScanPage extends StatefulWidget {
  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final ScanService _scanService = ScanService();

  void _startBarcodeScan() async {
    String barcodeResult = await _scanService.scanBarcode();
    if (barcodeResult.isNotEmpty) {
      // Navigate to the BarcodeResultPage with the barcode result
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BarcodeResultPage(barcodeResult: barcodeResult),
        ),
      );
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
