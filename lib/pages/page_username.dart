import 'package:flutter/material.dart';
import 'package:marihacks7/pages/page_camera_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isUserNew = true;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsNew();
  }

  Future<void> _createUser(String username) async {
    Uri uri = Uri.parse('http://v34l.com:8080/api/add');
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'userid': username}),
      );

      if (response.statusCode == 200) {
        // Si le serveur renvoie une réponse réussie, naviguez vers BarcodeScanPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => BarcodeScanPage()),
        );
      } else {
        // Gérez les erreurs de requête ici
        throw Exception('Failed to create user');
      }
    } catch (e) {
      // Gérez les exceptions de connexion ici
      print(e.toString());
    }
  }

  Future<void> _checkIfUserIsNew() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');
    if (userName != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BarcodeScanPage()),
      );
    } else {
      setState(() {
        _isUserNew = true;
      });
    }
  }

  Future<void> _setName() async {
    if (_nameController.text.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text.trim());
      await _createUser(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome back'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setName,
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: WelcomePage()));
}
