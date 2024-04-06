import 'dart:convert';                                                                                                                                                                                                                                                

import 'package:http/http.dart' as http;

class OpenFoodFactsAPI {
  Future<Album> fetchAlbum() async {
    final response = await http.get(Uri.parse(
        'https://world.openfoodfacts.net/api/v2/product/4001686396452'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }
}

class Album {
  final String code;
  final String product;

  const Album({required this.code, required this.product});

  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'code': String code,
        'product': String product,
      } =>
        Album(
          code: code,
          product: product,
        ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}
                                                                                                                                              