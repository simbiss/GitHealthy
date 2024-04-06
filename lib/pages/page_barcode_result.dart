import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:marihacks7/pages/page_scan_history.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:marihacks7/service/checkBarcode.dart';
import 'package:http/http.dart' as http;

Future<Product> fetchProduct(String barcodeResult) async {
  final response = await http.get(Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcodeResult'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class Product {
  final String code;
  final ProductDetails product;
  final int status;
  final String statusVerbose;

  Product(
      {required this.code,
      required this.product,
      required this.status,
      required this.statusVerbose});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      code: json['code'],
      product: ProductDetails.fromJson(json['product']),
      status: json['status'],
      statusVerbose: json['status_verbose'],
    );
  }
}

class ProductDetails {
  final String id;
  final List<String> keywords;
  final String brands;
  final String categories;
  final String productName;
  final String quantity;
  final List<String> allergensTags;
  final String imageFrontUrl;

  ProductDetails({
    required this.id,
    required this.keywords,
    required this.brands,
    required this.categories,
    required this.productName,
    required this.quantity,
    required this.allergensTags,
    required this.imageFrontUrl,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['_id'],
      keywords: List<String>.from(json['_keywords']),
      brands: json['brands'],
      categories: json['categories'],
      productName: json['product_name'],
      quantity: json['quantity'],
      allergensTags: List<String>.from(json['allergens_tags']),
      imageFrontUrl: json['image_front_url'],
    );
  }
}

class BarcodeResultPage extends StatefulWidget {
  final String barcodeResult;

  const BarcodeResultPage({super.key, required this.barcodeResult});

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();
}

class _BarcodeResultPageState extends State<BarcodeResultPage> {
  late Future<Product> futureProduct;
  int selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    futureProduct = fetchProduct(widget.barcodeResult);
  }

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();

  Future<void> _addBarcodeToDatabase(String barcodeResult) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('userName');

    if (username == null) {
      print("Username not found");
      return;
    }

    final Uri uri =
        Uri.parse('http://v34l.com:8080/api/$username/barcodes/$barcodeResult');

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        print('Barcode added successfully');
      } else {
        print('Failed to add barcode: ${response.body}');
      }
    } catch (e) {
      print('Error adding barcode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Scanned Barcode'),
        ),
        body: Center(
          child: FutureBuilder<Product>(
            future: futureProduct,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          topLeft: Radius.circular(20),
                        ),
                        child: Image.network(
                          snapshot.data!.product.imageFrontUrl,
                          height: 500,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      ListTile(
                          title: Text(snapshot.data!.product.productName),
                          subtitle: Text(snapshot.data!.code)),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
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
        ));
  }
}
