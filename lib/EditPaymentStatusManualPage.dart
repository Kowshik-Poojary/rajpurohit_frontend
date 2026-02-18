import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class EditPaymentStatusManualPage extends StatefulWidget {
  final int podId;
  final String currentStatus;

  const EditPaymentStatusManualPage({
    super.key,
    required this.podId,
    required this.currentStatus,
  });

  @override
  State<EditPaymentStatusManualPage> createState() =>
      _EditPaymentStatusManualPageState();
}

class _EditPaymentStatusManualPageState
    extends State<EditPaymentStatusManualPage> {
  String? _selectedStatus;
  bool _isLoading = false;
  final String apiUrl = '${ApiConfig.baseUrl}';

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
                  updatePaymentStatus();
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

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> updatePaymentStatus() async {
    final url = Uri.parse(
      '$apiUrl/update-payment-status-manual/${widget.podId}',
    );

    print("🟡 UPDATE REQUEST (Manual POD)");
    print("📍 URL: $url");
    print("📦 Pod ID: ${widget.podId}");
    print("📝 New Status: $_selectedStatus");

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status1': _selectedStatus}),
      );

      print("📥 Response Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to $_selectedStatus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update status: ${response.body}'),
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
        title: Text('Edit Payment Status'),
        backgroundColor: Color(0xff2a3368),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'Pod #${widget.podId}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
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
              onChanged: _isLoading
                  ? null
                  : (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            SizedBox(height: 30),
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
            ),
          ],
        ),
      ),
    );
  }
}