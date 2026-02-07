import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class origin_destination extends StatefulWidget {
  const origin_destination({super.key});

  @override
  State<origin_destination> createState() => _origin_destinationState();
}

class _origin_destinationState extends State<origin_destination> {

  List<String> locations = [];
  final TextEditingController _newLocationController = TextEditingController();
  final String apiUrl = '${ApiConfig.baseUrl}';

  @override
  void initState() {
    super.initState();
    print('🟡 initState triggered');
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/get-locations'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          locations = data.map((e) => e['city_name'] as String).toList();
        });
      }
    } catch (e) {
      print("Error fetching locations: $e");
    }
  }

  Future<void> addLocation(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/add-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'city_name': name.trim()}),
      );
      if (response.statusCode == 200) {
        _newLocationController.clear();
        fetchLocations();
      }
    } catch (e) {
      print("Error adding location: $e");
    }
  }

  Future<void> deleteLocation(String name) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/delete-location/$name'));
      if (response.statusCode == 200) {
        fetchLocations();
      }
    } catch (e) {
      print("Error deleting location: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff2a3368),
          title: Text('Edit Origin & Destination', style: TextStyle(color: Colors.white),),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _newLocationController,
                decoration: InputDecoration(
                  labelText: 'Add new city',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => addLocation(_newLocationController.text),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: locations.isEmpty
                    ? Center(child: Text('No cities available'))
                    : ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(locations[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteLocation(locations[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}
