import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// void main() => runApp(const MaterialApp(home: ProductDetailsPage(String)));

enum NutrientQuality { good, acceptable, bad }

const sugarGoodMax = 5.0;
const sugarAcceptableMax = 13.0;
const saturatedFatGoodMax = 0.5;
const saturatedFatAcceptableMax = 0.9;
const sodiumGoodMax = 0.15;
const sodiumAcceptableMax = 0.3;
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
  final String nutriScoreGrade;
  final String productName;

  Product({
    required this.imageUrl,
    required this.energyKcal,
    required this.proteins,
    required this.fiber,
    required this.sodium,
    required this.sugars,
    required this.saturatedFat,
    required this.nutriScoreGrade,
    required this.productName,
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
      nutriScoreGrade: json['nutriscore_grade'] ?? '',
      productName: json['product_name_en'] ?? '',
    );
  }

  Color getNutriScoreColor() {
    switch (nutriScoreGrade.toLowerCase()) {
      case 'a':
        return Colors.green;
      case 'b':
        return Colors.lightGreen;
      case 'c':
        return Colors.yellow;
      case 'd':
        return Colors.deepOrange;
      case 'e':
        return Colors.red;
      default:
        return Colors.grey; // In case the grade is not recognized
    }
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
        return 'Good amout of $nutrient';
      case NutrientQuality.acceptable:
        return 'Accecptable amouts of $nutrient';
      case NutrientQuality.bad:
        return 'Too much $nutrient';
      default:
        return 'Unknown amout of $nutrient ';
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

// Fetch Reccomendations

Future<List<Map<String, dynamic>>> fetchRecommendations(
    String barcodeResult) async {
  final response = await http.get(Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcodeResult&fields=categories_hierarchy'));

  if (response.statusCode == 200) {
    // If the server returns a 200 OK response, then parse the JSON.
    var data = jsonDecode(response.body);

    // Extract categories from the response
    var categories = data['product']['categories_hierarchy'];
    var categorieString =
        categories.map((category) => 'tag_0=$category').join('&');

    var url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?action=process&tagtype_0=categories&tag_contains_0=contains&$categorieString&json=1&nutriscore_grade=a&fields=code,product_name,image_front_url,nutriscore_grade&page_size=5');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the JSON response
        var data = json.decode(response.body);

        // Extract the items from the response
        List<Map<String, dynamic>> items = [];
        for (var product in data['products']) {
          if (product['nutriscore_grade'] == 'a' &&
              product['code'] != barcodeResult) {
            var item = {
              'code': product['code'],
              'nutriscore_grade': product['nutriscore_grade'],
              'product_name': product['product_name'],
              'image_url': product['image_front_url'],
            };
            items.add(item);
          }
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
  late Future<List<Map<String, dynamic>>> futureRecs;

  @override
  void initState() {
    super.initState();
    futureProduct = fetchProductData(widget.barcodeResult);
    futureRecs = fetchRecommendations(widget.barcodeResult);
    _addBarcodeToDatabase(widget.barcodeResult);
  }

  Future<void> _addBarcodeToDatabase(String barcodeResult) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? username = prefs.getString('userName');

  if (username == null) {
    print("Username not found");
    return;
  }

  final Uri uri = Uri.parse('http://v34l.com:8080/api/$username/barcodes/$barcodeResult');

  try {
    // Fetch data from OpenFoodFacts API
    final apiUrl = 'https://world.openfoodfacts.org/api/v0/product/$barcodeResult.json';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final productData = jsonDecode(response.body);
      final imageUrl = productData['product']['image_front_url'];
      final productName = productData['product']['product_name'];

      final addResponse = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "imageUrl": imageUrl,
          "productName": productName,
        }),
      );

      if (addResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Barcode added successfully')),
        );
      } else {
        print('Failed to add barcode: ${addResponse.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add barcode')),
        );
      }
    } else {
      print('Failed to fetch product data from OpenFoodFacts API');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch product data')),
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
        title: Text('Details'),
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
              return ProductDetails(snapshot.data!, futureRecs: futureRecs);
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
  final Future<List<Map<String, dynamic>>> futureRecs;

  ProductDetails(this.product, {required this.futureRecs});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(product.imageUrl, width: 90, fit: BoxFit.fitWidth),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: TextStyle(
                          fontSize: 28,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'Nutrition Facts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Text(
                        'Per 100g',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Calories: ${product.energyKcal.toStringAsFixed(2)} kcal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          color: product.getNutriScoreColor(),
          child: Text(
            'Nutri-Score: ${product.nutriScoreGrade.toUpperCase()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Divider(),
        ListTile(
          title:
              Text('Defaults', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(children: faultAttributes),
        ),
        ListTile(
          title:
              Text('Qualities', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(children: qualityAttributes),
        ),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureRecs,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to a detailed page when tapped
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(
                                  barcodeResult: item['code']),
                            ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.network(item['image_url'],
                              width: 100, height: 100),
                          SizedBox(height: 8),
                          Text(item['product_name']),
                          SizedBox(height: 4),
                          Text('Nutriscore: ${item['nutriscore_grade']}'),
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
    );
  }
}
