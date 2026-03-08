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

class _origin_destinationState extends State<origin_destination>
    with TickerProviderStateMixin {
  List<String> locations = [];
  final TextEditingController _newLocationController = TextEditingController();
  final String apiUrl = '${ApiConfig.baseUrl}';
  bool _isAdding = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    setupAnimations();
    fetchLocations();
  }

  void setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _newLocationController.dispose();
    super.dispose();
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
    setState(() => _isAdding = true);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/add-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'city_name': name.trim()}),
      );
      if (response.statusCode == 200) {
        _newLocationController.clear();
        await fetchLocations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location added'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error adding location: $e");
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> deleteLocation(String name) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/delete-location/$name'));
      if (response.statusCode == 200) {
        await fetchLocations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error deleting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff2a3368),
        title: const Text(
          'Origin & Destination',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xff2a3368).withOpacity(0.05),
              Colors.blue.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Add Location Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newLocationController,
                            style: const TextStyle(
                              color: Color(0xff2a3368),
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add new city',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: Colors.grey.shade400,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff2a3368), Color(0xff3d4a8a)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isAdding
                                  ? null
                                  : () => addLocation(_newLocationController.text),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: _isAdding
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Locations List
                  Expanded(
                    child: locations.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cities available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                locations[index],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff2a3368),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                onPressed: () =>
                                    deleteLocation(locations[index]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}