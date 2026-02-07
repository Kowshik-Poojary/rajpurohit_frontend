import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class address extends StatefulWidget {
  const address({super.key});

  @override
  State<address> createState() => _addressState();
}

class _addressState extends State<address> {
  TextEditingController _addressController = TextEditingController();
  String apiUrl = '${ApiConfig.baseUrl}';

  @override
  void initState() {
    super.initState();
    fetchAddress();
  }

  Future<void> fetchAddress() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/get-address'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _addressController.text = data['address'];
      } else {
        throw Exception('Failed to load address');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateAddress() async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/update-address'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'address': _addressController.text}),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address updated successfully')),
        );
      } else {
        throw Exception('Failed to update address');
      }
    } catch (e) {
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff2a3368),
          title: Text('Change Address', style: TextStyle(color: Colors.white),),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _addressController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Address',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateAddress,
                child: Text('Save'),
              )
            ],
          ),
        ),
    );
  }
}
