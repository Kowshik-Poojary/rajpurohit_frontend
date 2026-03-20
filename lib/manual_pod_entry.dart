import 'package:flutter/material.dart';
import 'package:rajpurohit/sidebar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';
import 'pod_data.dart';

class CommonTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final FocusNode focusNode;
  final Function(String)? onChanged;

  const CommonTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class manual_pod_entry extends StatefulWidget {
  const manual_pod_entry({super.key});

  @override
  State<manual_pod_entry> createState() => _manual_pod_entryState();
}

class _manual_pod_entryState extends State<manual_pod_entry> {
  // Manual POD Number and Date fields
  final TextEditingController _podNumber = TextEditingController();
  final TextEditingController _dateDay = TextEditingController();
  final TextEditingController _dateMonth = TextEditingController();
  final TextEditingController _dateYear = TextEditingController();

  // Regular fields
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  String selected_doc = 'Documents';
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _volweight = TextEditingController();
  final TextEditingController _piece = TextEditingController();
  final TextEditingController _rate = TextEditingController();

  // Focus nodes
  final FocusNode _podNumberFocus = FocusNode();
  final FocusNode _dateDayFocus = FocusNode();
  final FocusNode _dateMonthFocus = FocusNode();
  final FocusNode _dateYearFocus = FocusNode();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _volWeightFocus = FocusNode();
  final FocusNode _pieceFocus = FocusNode();
  final FocusNode _rateFocus = FocusNode();
  final FocusNode _senderFocus = FocusNode();
  final FocusNode _submitFocus = FocusNode();

  double _amount = 0.0;
  String selected_status = 'Unpaid';
  List<String> senderOptions = [];
  String? selectedOption;
  String apiUrl = '${ApiConfig.baseUrl}';
  List<String> locationOptions = [];
  String? _origin;
  String? _destination;
  List<String> nameSuggestions = [];

  Future<void> fetchSuggestions() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get-suggestions'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        nameSuggestions = data
            .map((e) => e['name'].toString())
            .toSet()
            .toList();
      });
    } else {
      print('❌ Failed to fetch suggestions');
    }
  }

  Future<void> fetchLocations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get-locations'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          locationOptions = data.map((e) => e['city_name'] as String).toList();
          if (_origin == null && locationOptions.isNotEmpty)
            _origin = locationOptions[0];
          if (_destination == null && locationOptions.length > 1)
            _destination = locationOptions[1];
        });
      } else {
        print('Failed to load cities');
      }
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  Future<void> fetchSenders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get-senders'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          senderOptions = data
              .map<String>((e) => e['name'].toString())
              .toList();
          if (selectedOption == null && senderOptions.isNotEmpty) {
            selectedOption = senderOptions[0];
          }
        });
      } else {
        print('❌ Failed to fetch senders');
      }
    } catch (e) {
      print('❌ Exception while fetching senders: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLocations();
    fetchSenders();
    fetchSuggestions();
  }

  void _clearForm() {
    setState(() {
      _podNumber.clear();
      _dateDay.clear();
      _dateMonth.clear();
      _dateYear.clear();
      _from.clear();
      _to.clear();
      _weight.clear();
      _volweight.clear();
      _piece.clear();
      _rate.clear();

      selected_doc = 'Documents';
      selected_status = 'Unpaid';
      selectedOption = senderOptions.isNotEmpty ? senderOptions[0] : null;
      _origin = locationOptions.isNotEmpty ? locationOptions[0] : null;
      _destination = locationOptions.length > 1 ? locationOptions[1] : null;

      _amount = 0;

      FocusScope.of(context).requestFocus(_podNumberFocus);
    });
  }

  Future<void> submitPodData() async {
    print("🟡 SUBMIT BUTTON PRESSED");

    if (_podNumber.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter POD number")),
      );
      return;
    }

    // ===== Extract number (remove R prefix if present) =====
    String podInput = _podNumber.text.trim().toUpperCase();

    // Remove "R" if user already typed it
    if (podInput.startsWith("R")) {
      podInput = podInput.substring(1);
    }

    // Parse the remaining number
    int? podNum = int.tryParse(podInput);

    if (podNum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter valid POD number (numbers only)")),
      );
      return;
    }

    if (_dateDay.text.isEmpty || _dateMonth.text.isEmpty || _dateYear.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please fill all date fields")),
      );
      return;
    }

    int? day = int.tryParse(_dateDay.text.trim());
    int? month = int.tryParse(_dateMonth.text.trim());
    int? year = int.tryParse(_dateYear.text.trim());

    if (day == null || month == null || year == null ||
        day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter valid date values")),
      );
      return;
    }

    if (_weight.text.isEmpty || _rate.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please fill all required fields")),
      );
      return;
    }

    // ===== Parse as doubles instead of integers =====
    double? weight = double.tryParse(_weight.text.trim());
    double? rate = double.tryParse(_rate.text.trim());

    if (weight == null || rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please enter valid decimal values")),
      );
      return;
    }

    // ===== Parse volumetric weight as double =====
    final double volWeight = double.tryParse(_volweight.text) ?? 0;
    if (volWeight == 0) {
      _amount = weight * rate;
    } else {
      _amount = volWeight * rate;
    }

    if (_from.text.trim().isEmpty ||
        _to.text.trim().isEmpty ||
        (_origin?.trim().isEmpty ?? true) ||
        (_destination?.trim().isEmpty ?? true) ||
        selected_doc.trim().isEmpty ||
        _piece.text.trim().isEmpty ||
        selected_status.trim().isEmpty ||
        selectedOption == null ||
        selectedOption!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please fill all required fields")),
      );
      return;
    }

    DateTime dateTime = DateTime(year, month, day);
    String formattedDate = dateTime.toIso8601String();

    var url = Uri.parse("${ApiConfig.baseUrl}/submitpod-manual");

    // ===== UPDATED: Send POD number WITHOUT R prefix =====
    // User enters: R12345 or 12345
    // Backend receives: 12345 (just the number)

    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "podNumber": podNum,  // Send WITHOUT R prefix (just the number)
        "date1": formattedDate,
        "from1": _from.text,
        "to1": _to.text,
        "doc": selected_doc,
        "origin": _origin,
        "destination": _destination,
        "weight": double.tryParse(_weight.text) ?? 0,
        "vol_weight": _volweight.text.isEmpty ? null : double.tryParse(_volweight.text),
        "pieces": int.tryParse(_piece.text) ?? 0,
        "amount": _amount,
        "status1": selected_status,
        "sender": selectedOption,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ POD ${data['podNumber']} submitted successfully"),
          duration: Duration(seconds: 2),
        ),
      );

      _clearForm();
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ POD number already exists or conflicts with auto-increment POD")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to submit data")),
      );
      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  }

  @override
  void dispose() {
    _podNumberFocus.dispose();
    _dateDayFocus.dispose();
    _dateMonthFocus.dispose();
    _dateYearFocus.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _originFocus.dispose();
    _destinationFocus.dispose();
    _weightFocus.dispose();
    _volWeightFocus.dispose();
    _pieceFocus.dispose();
    _rateFocus.dispose();
    _senderFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff2a3368),
        title: Text('Manual POD Entry', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      drawer: sidebar(),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manual POD Details',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff2a3368),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // POD Number Section
                            _buildFormSection(
                              label: 'POD Number',
                              child: SizedBox(
                                height: 52,
                                child: TextField(
                                  controller: _podNumber,
                                  focusNode: _podNumberFocus,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) {
                                    // ===== UPDATED: Remove R completely (don't show it in field) =====
                                    // Remove any R or r that user types
                                    String cleanValue = value.replaceAll('R', '').replaceAll('r', '').trim();

                                    // Update the field with clean number only
                                    if (cleanValue != _podNumber.text) {
                                      _podNumber.text = cleanValue;
                                      _podNumber.selection = TextSelection.fromPosition(
                                        TextPosition(offset: _podNumber.text.length),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '12345',
                                    helperText: 'Enter POD number (numbers only, e.g., 12345)',
                                    helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                    ),
                                    prefixIcon: Icon(Icons.inventory_2, color: Colors.grey.shade600, size: 20),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ),

                            // Date Section
                            _buildFormSection(
                              label: 'Date',
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: SizedBox(
                                      height: 52,
                                      child: CommonTextField(
                                        hintText: 'DD',
                                        controller: _dateDay,
                                        keyboardType: TextInputType.number,
                                        focusNode: _dateDayFocus,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('/', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: SizedBox(
                                      height: 52,
                                      child: CommonTextField(
                                        hintText: 'MM',
                                        controller: _dateMonth,
                                        keyboardType: TextInputType.number,
                                        focusNode: _dateMonthFocus,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('/', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: SizedBox(
                                      height: 52,
                                      child: CommonTextField(
                                        hintText: 'YYYY',
                                        controller: _dateYear,
                                        keyboardType: TextInputType.number,
                                        focusNode: _dateYearFocus,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // From Section
                            _buildFormSection(
                              label: 'From',
                              child: SizedBox(
                                height: 52,
                                child: Autocomplete<String>(
                                  focusNode: _fromFocus,
                                  textEditingController: _from,
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }
                                    return nameSuggestions.where(
                                          (option) => option
                                          .toLowerCase()
                                          .contains(textEditingValue.text.toLowerCase()),
                                    );
                                  },
                                  onSelected: (String selection) {
                                    _from.text = selection;
                                    FocusScope.of(context).requestFocus(_toFocus);
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (value) {
                                        onEditingComplete();
                                        FocusScope.of(context).requestFocus(_toFocus);
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter sender name',
                                        hintStyle: TextStyle(color: Colors.grey.shade500),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // To Section
                            _buildFormSection(
                              label: 'To',
                              child: SizedBox(
                                height: 52,
                                child: Autocomplete<String>(
                                  focusNode: _toFocus,
                                  textEditingController: _to,
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }
                                    return nameSuggestions.where(
                                          (option) => option
                                          .toLowerCase()
                                          .contains(textEditingValue.text.toLowerCase()),
                                    );
                                  },
                                  onSelected: (String selection) {
                                    _to.text = selection;
                                    FocusScope.of(context).requestFocus(_originFocus);
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (value) {
                                        onEditingComplete();
                                        FocusScope.of(context).requestFocus(_originFocus);
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter recipient name',
                                        hintStyle: TextStyle(color: Colors.grey.shade500),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Origin & Destination Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Origin',
                                    child: DropdownButtonFormField<String>(
                                      focusNode: _originFocus,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Select origin city',
                                        labelStyle: TextStyle(color: Colors.grey.shade600),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                      value: _origin,
                                      items: locationOptions.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() => _origin = newValue);
                                        Future.delayed(Duration(milliseconds: 100), () {
                                          FocusScope.of(context).requestFocus(_destinationFocus);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Destination',
                                    child: DropdownButtonFormField<String>(
                                      focusNode: _destinationFocus,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Select destination city',
                                        labelStyle: TextStyle(color: Colors.grey.shade600),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                      value: _destination,
                                      items: locationOptions.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() => _destination = newValue);
                                        Future.delayed(Duration(milliseconds: 100), () {
                                          FocusScope.of(context).requestFocus(_weightFocus);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Contents Section
                            _buildFormSection(
                              label: 'Contents',
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  _buildToggleButton(
                                    label: 'Documents',
                                    isSelected: selected_doc == 'Documents',
                                    onPressed: () {
                                      setState(() => selected_doc = 'Documents');
                                    },
                                  ),
                                  _buildToggleButton(
                                    label: 'Non-Documents',
                                    isSelected: selected_doc == 'Non-Docx',
                                    onPressed: () {
                                      setState(() => selected_doc = 'Non-Docx');
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Weight Details Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Weight (kg)',
                                    child: CommonTextField(
                                      hintText: 'e.g., 10.5',
                                      controller: _weight,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      focusNode: _weightFocus,
                                      onChanged: (value) {
                                        // Limit to 2 decimal places
                                        if (value.contains('.')) {
                                          List<String> parts = value.split('.');
                                          if (parts[1].length > 2) {
                                            _weight.text = '${parts[0]}.${parts[1].substring(0, 2)}';
                                            _weight.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _weight.text.length),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Vol. Weight (kg)',
                                    child: CommonTextField(
                                      hintText: 'e.g., 8.75',
                                      controller: _volweight,
                                      focusNode: _volWeightFocus,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (value) {
                                        // Limit to 2 decimal places
                                        if (value.contains('.')) {
                                          List<String> parts = value.split('.');
                                          if (parts[1].length > 2) {
                                            _volweight.text = '${parts[0]}.${parts[1].substring(0, 2)}';
                                            _volweight.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _volweight.text.length),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Pieces Details Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Pieces',
                                    child: CommonTextField(
                                      hintText: 'Enter number of pieces',
                                      controller: _piece,
                                      focusNode: _pieceFocus,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Rate (₹/kg)',
                                    child: TextField(
                                      controller: _rate,
                                      focusNode: _rateFocus,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {
                                        // Limit to 2 decimal places
                                        if (value.contains('.')) {
                                          List<String> parts = value.split('.');
                                          if (parts[1].length > 2) {
                                            _rate.text = '${parts[0]}.${parts[1].substring(0, 2)}';
                                            _rate.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _rate.text.length),
                                            );
                                          }
                                        }
                                      },
                                      onSubmitted: (_) {
                                        FocusScope.of(context).requestFocus(_senderFocus);
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'e.g., 50.75',
                                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Amount Calculation
                            _buildFormSection(
                              label: 'Amount',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          if (_weight.text.isEmpty || _rate.text.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Please enter both weight and rate"),
                                              ),
                                            );
                                            return;
                                          }

                                          // ===== Parse as doubles =====
                                          final double weight = double.tryParse(_weight.text) ?? 0;
                                          final double volWeight = double.tryParse(_volweight.text) ?? 0;
                                          final double rate = double.tryParse(_rate.text) ?? 0;

                                          if (volWeight == 0) {
                                            _amount = (weight * rate);
                                          } else {
                                            _amount = (volWeight * rate);
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.calculate),
                                      label: Text('Calculate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      border: Border.all(color: Colors.blue.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₹${_amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff2a3368),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status Section
                            _buildFormSection(
                              label: 'Payment Status',
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  _buildToggleButton(
                                    label: 'Paid',
                                    isSelected: selected_status == 'Paid',
                                    onPressed: () {
                                      setState(() => selected_status = 'Paid');
                                    },
                                  ),
                                  _buildToggleButton(
                                    label: 'Unpaid',
                                    isSelected: selected_status == 'Unpaid',
                                    onPressed: () {
                                      setState(() => selected_status = 'Unpaid');
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Sender Section
                            _buildFormSection(
                              label: 'Sender',
                              child: DropdownButtonFormField<String>(
                                focusNode: _senderFocus,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Select sender',
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                value: selectedOption,
                                items: senderOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() => selectedOption = newValue);
                                  Future.delayed(Duration(milliseconds: 100), () {
                                    FocusScope.of(context).requestFocus(_submitFocus);
                                  });
                                },
                              ),
                            ),

                            // Action Buttons
                            SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    focusNode: _submitFocus,
                                    onPressed: () async {
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("Confirm Submission"),
                                            content: const Text("Are you sure you want to submit this POD data?"),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xff2a3368),
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text("Submit"),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm ?? false) {
                                        submitPodData();
                                      }
                                    },
                                    icon: Icon(Icons.check_circle),
                                    label: Text('Submit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xff2a3368),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build form sections with labels
  Widget _buildFormSection({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff2a3368),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // Helper method to build toggle buttons
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Color(0xff2a3368) : Colors.grey.shade100,
        foregroundColor: isSelected ? Colors.white : Color(0xff2a3368),
        elevation: isSelected ? 2 : 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Color(0xff2a3368) : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}