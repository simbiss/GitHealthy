import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:marihacks7/pages/page_scan_history.dart';

class BarcodeResultPage extends StatefulWidget {
  final String barcodeResult;

  const BarcodeResultPage({Key? key, required this.barcodeResult})
      : super(key: key);

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();
}

class _BarcodeResultPageState extends State<BarcodeResultPage> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanned Barcode'),
      ),
      body: Center(
        child: Text(
          widget.barcodeResult,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Container(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: GNav(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              tabBackgroundColor: Theme.of(context).colorScheme.primary,
              activeColor: Theme.of(context).colorScheme.onPrimary,
              gap: 12,
              padding: const EdgeInsets.all(20),
              selectedIndex: 0,
              onTabChange: (index) {
                setState(() {
                  selectedIndex = index;
                  if (selectedIndex == 0) {
                  /* 
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            pageProfil(), //remplacer par le nom de la  page,
                      ),
                    );
                    */
                  }
                  if (selectedIndex == 1) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            HistoryPage(),
                      ),
                    );
                  }
                  if (selectedIndex == 2) {
                    /* 
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            pageProfil(), //remplacer par le nom de la  page,
                      ),
                    );
                    */
                  }
                });
              },
              tabs: const [
                GButton(
                  icon: Icons.map_outlined,
                  text: 'Map',
                ),
                GButton(
                  icon: Icons.sunny,
                  text: 'Weather',
                ),
                GButton(
                  icon: Icons.account_circle,
                  text: 'Profile',
                )
              ],
            ),
          ),
        )
    );
  }
}
