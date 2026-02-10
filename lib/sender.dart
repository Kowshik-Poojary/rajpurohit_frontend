import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class sender extends StatefulWidget {
  const sender({super.key});

  @override
  State<sender> createState() => _senderState();
}

class _senderState extends State<sender> {

  List<String> senders = [];
  final TextEditingController _senderController = TextEditingController();
  final String apiUrl = '${ApiConfig.baseUrl}';

  @override
  void initState() {
    super.initState();
    fetchSenders();
  }

  Future<void> fetchSenders() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/get-senders'));
      print("📥 Sender Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          senders = data.map<String>((e) => e['name'].toString()).toList();
        });
      }
    } catch (e) {
      print("❌ Error fetching senders: $e");
    }
  }

  Future<void> addSender(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/add-sender'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name.trim()}),
      );
      if (response.statusCode == 200) {
        _senderController.clear();
        fetchSenders();
      }
    } catch (e) {
      print("❌ Error adding sender: $e");
    }
  }

  Future<void> deleteSender(String name) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/delete-sender/$name'));
      if (response.statusCode == 200) {
        fetchSenders();
      }
    } catch (e) {
      print("❌ Error deleting sender: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff2a3368),
          title: Text('Edit Sender Data', style: TextStyle(color: Colors.white),),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _senderController,
                decoration: InputDecoration(
                  labelText: 'Add new sender',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => addSender(_senderController.text),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: senders.isEmpty
                    ? Center(child: Text('No senders available'))
                    : ListView.builder(
                  itemCount: senders.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(senders[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteSender(senders[index]),
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
