import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:marihacks7/pages/page_camera_scanner.dart';
import 'package:marihacks7/pages/page_scan_history.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<String> categories;
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
      categories: List<String>.from(json['categories']),
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
  late Future<List<Map<String, dynamic>>> futureRecs;
  int selectedIndex = 1;
  @override
  void initState() {
    super.initState();
    futureProduct = fetchProduct(widget.barcodeResult);
    futureRecs = fetchRecommendations(widget.barcodeResult);
  }

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

Future<List<Map<String, dynamic>>> fetchRecommendations(String barcodeResult) async {
  final response = await http.get(Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcodeResult&fields=categories'));

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, then parse the JSON.
    var data = json.decode(response.body);

    // Extract categories from the response
    var categories = (data['product'] as Map<String, dynamic>)['categories_tags'] as List<dynamic>;
    var categorieString = categories.map((category) => 'tag_0=$category').join('&');

    var url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?action=process&tagtype_0=categories&tag_contains_0=contains&$categorieString&json=1&nutriscore_grade=a&fields=code,product_name,image_front_url&page_size=5');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the JSON response
        var data = json.decode(response.body);

        // Extract the items from the response
        List<Map<String, dynamic>> items = [];
        for (var product in data['products']) {
          var item = {
            'code': product['code'],
            'product_name': product['product_name'],
            'image_url': product['image_front_url'],
          };
          items.add(item);
        }

        // Return the list of items
        return items;
      } else {
        print('Request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  } else {
    // If the server does not return a 200 OK response, throw an exception.
    throw Exception('Failed to load data');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Barcode'),
      ),
      body: Center(
  child: Column(
    children: [
      FutureBuilder<Product>(
        future: futureProduct,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.pink[900]!,
                        width: 2.0,
                      ),
                    ),
                    child: Image.network(snapshot.data!.product.imageFrontUrl),
                  ),
                  Text(snapshot.data!.code),
                  Text(snapshot.data!.product.productName),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return CircularProgressIndicator();
        },
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureRecs,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var item = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.network(item['image_url'], width: 100, height: 100),
                        SizedBox(height: 8),
                        Text(item['product_name']),
                        SizedBox(height: 4),
                        Text('Code: ${item['code']}'),
                      ],
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    ],
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
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            HistoryPage(),
                      ),
                    );
                  }
                  if (selectedIndex == 1) {
                    // startBarcodeScan;
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
                  icon: Icons.history,
                  text: 'History',
                ),
                GButton(
                  icon: Icons.barcode_reader,
                  text: 'Scan',
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
