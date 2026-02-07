import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class EditVolWeightPage extends StatefulWidget {
  final int podId;
  final String currentVolWeight;
  final int weight;

  const EditVolWeightPage({
    super.key,
    required this.podId,
    required this.currentVolWeight,
    required this.weight,
  });

  @override
  State<EditVolWeightPage> createState() => _EditVolWeightPageState();
}

class _EditVolWeightPageState extends State<EditVolWeightPage> {
  final TextEditingController _volWeightController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  final String apiUrl = '${ApiConfig.baseUrl}'; // your backend IP

  @override
  void initState() {
    super.initState();
    _volWeightController.text = widget.currentVolWeight;
  }


  Future<void> updateVolWeight() async {
    final volWeight = int.tryParse(_volWeightController.text) ?? 0;
    final rate = int.tryParse(_rateController.text) ?? 0;
    final fallbackWeight = widget.weight;

    final amount = (volWeight > 0 ? volWeight : fallbackWeight) * rate;

    final url = Uri.parse('${ApiConfig.baseUrl}/update-volweight/${widget.podId}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vol_weight': volWeight,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vol Weight & Amount updated')),
        );
        Navigator.pop(context); // Go back
      } else {
        print('❌ Failed to update: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception: $e');
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
              decoration: InputDecoration(
                labelText: 'Vol Weight',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Rate',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateVolWeight,
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff2a3368),
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
