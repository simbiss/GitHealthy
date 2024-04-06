import 'package:flutter/material.dart';
import 'package:marihacks7/pages/page_username.dart';
import 'package:marihacks7/service/scan_service.dart';
import 'package:marihacks7/pages/page_barcode_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeScanPage extends StatefulWidget {
  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final ScanService _scanService = ScanService();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');

    if (userName != null) {
      setState(() {
        _userName = userName;
      });
    }
  }

  Future<void> _clearUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomePage()));
  }

  void _startBarcodeScan() async {
    String barcodeResult = await _scanService.scanBarcode();
    if (barcodeResult.isNotEmpty) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_userName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text('Welcome, $_userName',
                    style: Theme.of(context).textTheme.headline6),
              ),
            ElevatedButton(
              onPressed: _startBarcodeScan,
              child: Text('Start Scanning'),
            ),
            SizedBox(height: 10), // Spacing between buttons
            ElevatedButton(
              onPressed: _clearUserName,
              child: Text('Reset User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .red, // Provide a different color to indicate a destructive action
              ),
            ),
          ],
        ),
      ),
    );
  }
}
