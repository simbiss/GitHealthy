import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsAPI {
  static Future<Map<String, dynamic>> fetchProduct(String barcode) async {
    final response = await http.get(Uri.parse('https://world.openfoodfacts.net/api/v2/product/$barcode'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception('Failed to load product');
    }
  }
}