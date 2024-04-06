import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:marihacks7/service/checkBarcode.dart';
import 'package:http/http.dart' as http;

  Future<Product> fetchProduct() async {
    final response = await http.get(Uri.parse(
        'https://world.openfoodfacts.net/api/v2/product/4001686396452'));

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

  Product({required this.code, required this.product, required this.status, required this.statusVerbose});

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

  @override
  void initState() {
    super.initState();
    futureProduct = fetchProduct();
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
              return Text(snapshot.data!.product.productName);
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}