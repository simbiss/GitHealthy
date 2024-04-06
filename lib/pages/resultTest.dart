import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// void main() => runApp(const MaterialApp(home: ProductDetailsPage(String)));

enum NutrientQuality { good, acceptable, bad }

const sugarGoodMax = 5.0;
const sugarAcceptableMax = 15.0;
const saturatedFatGoodMax = 1.5;
const saturatedFatAcceptableMax = 5.0;
const sodiumGoodMax = 150.0;
const sodiumAcceptableMax = 500.0;
const fiberGoodMin = 3.0;
const fiberAcceptableMin = 6.0;
const proteinGoodMin = 5.0;
const proteinAcceptableMin = 10.0;

// Product model
class Product {
  final String imageUrl;
  final double energyKcal;
  final double proteins;
  final double fiber;
  final double sodium;
  final double sugars;
  final double saturatedFat;

  Product({
    required this.imageUrl,
    required this.energyKcal,
    required this.proteins,
    required this.fiber,
    required this.sodium,
    required this.sugars,
    required this.saturatedFat,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      imageUrl: json['image_front_url'] ?? '',
      energyKcal: json['nutriments']['energy-kcal_100g']?.toDouble() ?? 0.0,
      proteins: json['nutriments']['proteins_100g']?.toDouble() ?? 0.0,
      fiber: json['nutriments']['fiber_100g']?.toDouble() ?? 0.0,
      sodium: json['nutriments']['sodium_100g']?.toDouble() ?? 0.0,
      sugars: json['nutriments']['sugars_100g']?.toDouble() ?? 0.0,
      saturatedFat: json['nutriments']['saturated-fat_100g']?.toDouble() ?? 0.0,
    );
  }

  NutrientQuality getQuality(
      double value, double goodMax, double acceptableMax) {
    if (value <= goodMax) {
      return NutrientQuality.good;
    } else if (value <= acceptableMax) {
      return NutrientQuality.acceptable;
    } else {
      return NutrientQuality.bad;
    }
  }

  NutrientQuality getSugarQuality() =>
      getQuality(sugars, sugarGoodMax, sugarAcceptableMax);
  NutrientQuality getSaturatedFatQuality() =>
      getQuality(saturatedFat, saturatedFatGoodMax, saturatedFatAcceptableMax);
  NutrientQuality getSodiumQuality() =>
      getQuality(sodium, sodiumGoodMax, sodiumAcceptableMax);
  NutrientQuality getFiberQuality() =>
      getQuality(fiber, fiberGoodMin, fiberAcceptableMin);
  NutrientQuality getProteinQuality() =>
      getQuality(proteins, proteinGoodMin, proteinAcceptableMin);

  Color getNutrientColor(NutrientQuality quality) {
    switch (quality) {
      case NutrientQuality.good:
        return Colors.green;
      case NutrientQuality.acceptable:
        return Colors.orange;
      case NutrientQuality.bad:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getNutrientDescription(NutrientQuality quality, String nutrient) {
    switch (quality) {
      case NutrientQuality.good:
        return 'Bonne quantité de $nutrient';
      case NutrientQuality.acceptable:
        return 'Quantité de $nutrient acceptable';
      case NutrientQuality.bad:
        return 'Trop de $nutrient';
      default:
        return 'Quantité de $nutrient inconnue';
    }
  }
}

// Fetch product data from the API
Future<Product> fetchProductData(String barcodeResult) async {
  final response = await http.get(Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcodeResult'));

  if (response.statusCode == 200) {
    return Product.fromJson(json.decode(response.body)['product']);
  } else {
    throw Exception('Failed to load product');
  }
}

// Main product details page
class ProductDetailsPage extends StatefulWidget {
  final String barcodeResult;

  const ProductDetailsPage({Key? key, required this.barcodeResult})
      : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Future<Product> futureProduct;

  @override
  void initState() {
    super.initState();
    futureProduct = fetchProductData(widget.barcodeResult);

    _addBarcodeToDatabase(widget.barcodeResult);
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Barcode added successfully')),
        );
      } else {
        print('Failed to add barcode: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add barcode')),
        );
      }
    } catch (e) {
      print('Error adding barcode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding barcode')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Produit'),
      ),
      body: FutureBuilder<Product>(
        future: fetchProductData(widget.barcodeResult),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('Product not found'));
            } else {
              return ProductDetails(snapshot.data!);
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// Widget that displays the product details
class ProductDetails extends StatelessWidget {
  final Product product;

  ProductDetails(this.product);

  Widget _buildAttributeRow(IconData icon, String nutrient, double amount) {
    NutrientQuality quality;
    String description;
    String amountString = amount.toStringAsFixed(2);
    switch (nutrient) {
      case "Sugars":
        quality = product.getSugarQuality();
        break;
      case "Saturated Fat":
        quality = product.getSaturatedFatQuality();
        break;
      case "Sodium":
        quality = product.getSodiumQuality();
        break;
      case "Fiber":
        quality = product.getFiberQuality();
        break;
      case "Proteins":
        quality = product.getProteinQuality();
        break;
      default:
        quality = NutrientQuality.bad; // Or some default
        break;
    }

    description = product.getNutrientDescription(quality, nutrient);
    Color color = product.getNutrientColor(quality);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8.0),
          Expanded(child: Text(description)),
          Text(
            '[$amountString]',
            style: TextStyle(color: color),
          ),
          SizedBox(width: 8.0),
          Icon(
            quality == NutrientQuality.good ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> faultAttributes = [];
    List<Widget> qualityAttributes = [];

    // Example for Sugars
    var sugarQuality = product.getSugarQuality();
    var sugarAttribute = _buildAttributeRow(
        Icons.emoji_food_beverage_outlined, "Sugars", product.sugars);
    if (sugarQuality != NutrientQuality.good) {
      faultAttributes.add(sugarAttribute);
    } else {
      qualityAttributes.add(sugarAttribute);
    }

    // For Saturated Fat
    var satFatQuality = product.getSaturatedFatQuality();
    var satFatAttribute = _buildAttributeRow(
        Icons.fastfood_outlined, "Saturated Fat", product.saturatedFat);
    (satFatQuality != NutrientQuality.good
            ? faultAttributes
            : qualityAttributes)
        .add(satFatAttribute);

    // For Sodium
    var sodiumQuality = product.getSodiumQuality();
    var sodiumAttribute = _buildAttributeRow(
        Icons.local_dining_outlined, "Sodium", product.sodium);
    (sodiumQuality != NutrientQuality.good
            ? faultAttributes
            : qualityAttributes)
        .add(sodiumAttribute);

    // For Fiber
    var fiberQuality = product.getFiberQuality();
    var fiberAttribute =
        _buildAttributeRow(Icons.grass_outlined, "Fiber", product.fiber);
    (fiberQuality != NutrientQuality.good ? faultAttributes : qualityAttributes)
        .add(fiberAttribute);

    // For Proteins
    var proteinQuality = product.getProteinQuality();
    var proteinAttribute = _buildAttributeRow(
        Icons.fitness_center_outlined, "Proteins", product.proteins);
    (proteinQuality != NutrientQuality.good
            ? faultAttributes
            : qualityAttributes)
        .add(proteinAttribute);

    return ListView(
      children: <Widget>[
        Image.network(product.imageUrl, height: 200, fit: BoxFit.cover),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Product Rating',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Divider(),
        ListTile(
          title: Text('Défauts', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(children: faultAttributes),
        ),
        ListTile(
          title:
              Text('Qualités', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(children: qualityAttributes),
        ),
        // ... other widgets ...
      ],
    );
  }
}