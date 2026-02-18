import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class EditVolWeightManualPage extends StatefulWidget {
  final int podId;
  final String currentVolWeight;
  final int weight;

  const EditVolWeightManualPage({
    super.key,
    required this.podId,
    required this.currentVolWeight,
    required this.weight,
  });

  @override
  State<EditVolWeightManualPage> createState() =>
      _EditVolWeightManualPageState();
}

class _EditVolWeightManualPageState extends State<EditVolWeightManualPage> {
  final TextEditingController _volWeightController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  bool _isLoading = false;
  final String apiUrl = '${ApiConfig.baseUrl}';

  @override
  void initState() {
    super.initState();
    _volWeightController.text = widget.currentVolWeight;
  }

  @override
  void dispose() {
    _volWeightController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> showLoginPrompt() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Map<String, String> credentials = {
      'rajpurohit': '1008',
      'mahendra': '9892',
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Credentials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                final enteredUsername = usernameController.text.trim();
                final enteredPassword = passwordController.text;

                if (credentials.containsKey(enteredUsername) &&
                    credentials[enteredUsername] == enteredPassword) {
                  Navigator.pop(context);
                  updateVolWeight();
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Invalid username or password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateVolWeight() async {
    final volWeight = int.tryParse(_volWeightController.text) ?? 0;
    final rate = int.tryParse(_rateController.text) ?? 0;
    final fallbackWeight = widget.weight;

    final amount = (volWeight > 0 ? volWeight : fallbackWeight) * rate;

    final url =
    Uri.parse('$apiUrl/update-volweight-manual/${widget.podId}');

    print("🟡 UPDATE REQUEST (Manual POD)");
    print("📍 URL: $url");
    print("📦 Pod ID: ${widget.podId}");
    print("📦 Vol Weight: $volWeight");
    print("📦 Amount: $amount");

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vol_weight': volWeight,
          'amount': amount,
        }),
      );

      print("📥 Response Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Vol Weight & Amount updated')),
        );
        Navigator.pop(context);
      } else {
        print('❌ Failed to update: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        title: Text('Edit Vol Weight'),
        backgroundColor: Color(0xff2a3368),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _volWeightController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Vol Weight',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Rate',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : showLoginPrompt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2a3368),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text('Save', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}