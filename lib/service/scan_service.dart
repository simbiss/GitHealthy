import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanService {
  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<String> scanBarcode() async {
    // Ensure the camera permission is granted
    await requestCameraPermission();

    // Attempt to scan the barcode
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666",
      "Cancel",
      true,
      ScanMode.BARCODE,
    );

    return barcodeScanRes == "-1" ? "" : barcodeScanRes;
  }
}
