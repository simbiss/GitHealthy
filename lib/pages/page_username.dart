import 'package:flutter/material.dart';
import 'package:marihacks7/pages/page_camera_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      setState(() {
        _isUserNew = false;
      });
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
