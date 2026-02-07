import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class EditPaymentStatusPage extends StatefulWidget {
  final int podId; // ID of the record
  final String currentStatus;

  const EditPaymentStatusPage({
    super.key,
    required this.podId,
    required this.currentStatus,
  });

  @override
  State<EditPaymentStatusPage> createState() => _EditPaymentStatusPageState();
}

class _EditPaymentStatusPageState extends State<EditPaymentStatusPage> {
  String? _selectedStatus;
  final String apiUrl = '${ApiConfig.baseUrl}'; // replace with your IP

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
                  updateStatus();
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid username or password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> updateStatus() async {
    final url = Uri.parse('$apiUrl/update-payment-status/${widget.podId}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status1': _selectedStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $_selectedStatus')),
        );
        Navigator.pop(context); // Go back to previous page
      } else {
        print('❌ Failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        title: Text('Edit Payment Status'),
        backgroundColor: Color(0xff2a3368),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
              ),
              items: ['Paid', 'Unpaid'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: showLoginPrompt,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff2a3368),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text('Save', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
