import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajpurohit/sidebar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey;
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';
import 'config/api.dart';

class PodData {
  final String podNumber;
  final String date;
  final String formattedDate;
  final String from;
  final String to;
  final String origin;
  final String destination;
  final String doc;
  final double weight;
  final double? volWeight;
  final int pieces;
  final double amount;
  final String status;
  final String sender;

  PodData({
    required this.podNumber,
    required this.date,
    required this.formattedDate,
    required this.from,
    required this.to,
    required this.origin,
    required this.destination,
    required this.doc,
    required this.weight,
    required this.volWeight,
    required this.pieces,
    required this.amount,
    required this.status,
    required this.sender,
  });
}

class CommonTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final FocusNode focusNode;
  final IconData? prefixIcon;
  final Function(String)? onChanged;

  const CommonTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
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
      style: const TextStyle(color: Color(0xff2a3368), fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade400) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff2a3368), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class AutocompleteTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final IconData? prefixIcon;
  final List<String> suggestions;
  final Function(String)? onSelected;

  const AutocompleteTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.prefixIcon,
    required this.suggestions,
    this.onSelected,
  });

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  int _selectedIndex = -1;
  late FocusNode _keyboardListenerFocus;

  @override
  void initState() {
    super.initState();
    _keyboardListenerFocus = FocusNode();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _keyboardListenerFocus.dispose();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
        _selectedIndex = -1;
      });
    }
  }

  void _filterSuggestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = [];
        _showSuggestions = false;
        _selectedIndex = -1;
      } else {
        _filteredSuggestions = widget.suggestions
            .where((suggestion) =>
            suggestion.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showSuggestions = _filteredSuggestions.isNotEmpty;
        _selectedIndex = -1;
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    setState(() {
      _showSuggestions = false;
      _selectedIndex = -1;
    });
    widget.onSelected?.call(suggestion);

    if (widget.nextFocusNode != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(widget.nextFocusNode!);
      });
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!_showSuggestions || _filteredSuggestions.isEmpty) return;

    if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredSuggestions.length;
      });
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1) < 0
            ? _filteredSuggestions.length - 1
            : _selectedIndex - 1;
      });
    } else if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      if (_selectedIndex >= 0 && _selectedIndex < _filteredSuggestions.length) {
        _selectSuggestion(_filteredSuggestions[_selectedIndex]);
      }
    } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
      setState(() {
        _showSuggestions = false;
        _selectedIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardListenerFocus,
      onKey: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: _filterSuggestions,
            style: const TextStyle(color: Color(0xff2a3368), fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: Colors.grey.shade400)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff2a3368), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          if (_showSuggestions && _filteredSuggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.builder(
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _filteredSuggestions[index];
                    final isSelected = index == _selectedIndex;

                    return Container(
                      color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
                      child: ListTile(
                        dense: true,
                        hoverColor: Colors.blue.withOpacity(0.1),
                        title: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? const Color(0xff2a3368) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class add_data extends StatefulWidget {
  const add_data({super.key});

  @override
  State<add_data> createState() => _add_dataState();
}

class _add_dataState extends State<add_data> {
  final TextEditingController _from = TextEditingController();
  final TextEditingController _to = TextEditingController();
  String selected_doc = 'Documents';
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _volweight = TextEditingController();
  final TextEditingController _piece = TextEditingController();
  final TextEditingController _rate = TextEditingController();
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
  PodData? submittedPod;
  String address = '';
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
    fetchAddress();
    fetchLocations();
    fetchSenders();
    fetchSuggestions();
  }

  Future<String> fetchAddress() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get-address'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['address'];
    } else {
      print("Failed to load address");
      return 'No address found';
    }
  }

  Future<void> generateAndPreviewInvoice(
      BuildContext context,
      PodData pod,
      ) async {
    final fetchedAddress = await fetchAddress();
    print("Generating PDF with address: $fetchedAddress");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Invoice Preview')),
          body: PdfPreview(
            build: (format) => _generatePdf(format, pod, fetchedAddress),
          ),
        ),
      ),
    );
  }

  pw.Widget buildInvoice(PodData pod, pw.ImageProvider image, String address) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 160,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Stack(
                      children: [
                        pw.Image(image),
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              '    M/S JOGSINGH.A.RAJPUROHIT',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'GSTIN 27BUXPS4675M1ZA',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 120,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: pw.Text(address, style: pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(
                    width: 140,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: 140,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: pw.Row(
                            children: [
                              pw.Text('Date - '),
                              pw.Text(pod.formattedDate),
                            ],
                          ),
                        ),
                        pw.Container(
                          width: 140,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: pw.Row(
                            children: [
                              pw.Text('AWB no. - '),
                              pw.Text(pod.podNumber),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 140,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            color: PdfColor.fromInt(0xff2a3368),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 1,
                          ),
                          child: pw.Text(
                            'Origin',
                            style: pw.TextStyle(color: PdfColors.white),
                          ),
                        ),
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 1,
                          ),
                          child: pw.Text(pod.origin),
                        ),
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            color: PdfColor.fromInt(0xff2a3368),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 1,
                          ),
                          child: pw.Text(
                            'Destination',
                            style: pw.TextStyle(color: PdfColors.white),
                          ),
                        ),
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 1,
                          ),
                          child: pw.Text(pod.destination),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Container(
                    width: 280,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('From'),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          pod.from,
                          style: pw.TextStyle(
                            fontSize: 15,
                            color: PdfColor.fromInt(0xff2a3368),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 280,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('To'),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          pod.to,
                          style: pw.TextStyle(
                            fontSize: 15,
                            color: PdfColor.fromInt(0xff2a3368),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Contents',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(pod.doc),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Weight',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('${pod.weight} kg'),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Vol. Weight',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('${pod.volWeight} kg'),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Pieces',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('${pod.pieces}'),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('${pod.amount.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 93.33,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(pod.status),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Container(
                    width: 280,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'I/WE HEREBY DECLARE THAT THIS CONSIGNMENT DOES NOT CONTAIN ANY CASH, SHARE CERTIFICATES, BEARER CHEQUES, JEWELLERY, CONTRABAND, DRUGS, WEAPONS, EXPLOSIVES, OR ANY ITEM PROHIBITED UNDER THE LAWS AND REGULATIONS OF '
                          'THE CENTRAL, STATE, OR LOCAL AUTHORITIES.',
                      style: pw.TextStyle(
                        fontSize: 7,
                        lineSpacing: 2,
                        wordSpacing: 1,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 140,
                        height: 25,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          color: PdfColor.fromInt(0xff2a3368),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'Sender - ',
                              style: pw.TextStyle(color: PdfColors.white),
                            ),
                            pw.Text(
                              pod.sender,
                              style: pw.TextStyle(color: PdfColors.white),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 140,
                        height: 25,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Sign - '),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 140,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Receiving Sign & Stamp',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(
      PdfPageFormat format,
      PodData pod,
      String address,
      ) async {
    final pdf = pw.Document();
    final imageBytes = await rootBundle.load('assets/images/logo1.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => pw.Column(
          children: List.generate(
            3,
                (index) => pw.Column(
              children: [
                buildInvoice(pod, image, address),
                if (index < 2)
                  pw.Divider(),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> submitPodData() async {
    print("🟡 SUBMIT BUTTON PRESSED");
    if (_weight.text.isEmpty || _rate.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all required fields")),
      );
      return;
    }

    double? weight = double.tryParse(_weight.text.trim());
    double? rate = double.tryParse(_rate.text.trim());

    if (weight == null || rate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Please enter valid decimal values")));
      return;
    }

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
        _weight.text.trim().isEmpty ||
        _piece.text.trim().isEmpty ||
        selected_status.trim().isEmpty ||
        selectedOption == null ||
        selectedOption!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all required fields")),
      );
      return;
    }

    var url = Uri.parse("${ApiConfig.baseUrl}/submitpod");

    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "from1": _from.text,
        "to1": _to.text,
        "doc": selected_doc,
        "origin": _origin,
        "destination": _destination,
        "weight": double.tryParse(_weight.text) ?? 0,
        "vol_weight": _volweight.text.isEmpty
            ? null
            : double.tryParse(_volweight.text),
        "pieces": int.tryParse(_piece.text) ?? 0,
        "amount": _amount,
        "status1": selected_status,
        "sender": selectedOption,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Backend should return podNumber - format it with R if needed for display
      String podNumberDisplay = data['podNumber'].toString();
      if (!podNumberDisplay.startsWith('R')) {
        podNumberDisplay = 'R$podNumberDisplay';
      }

      PodData pod = PodData(
        podNumber: podNumberDisplay,
        date: data['date1'],
        formattedDate: DateFormat(
          'd-MM-yyyy',
        ).format(DateTime.parse(data['date1'])),
        from: data['from1'],
        to: data['to1'],
        origin: data['origin'],
        destination: data['destination'],
        doc: data['doc'],
        weight: (data['weight'] as num).toDouble(),
        volWeight: data['vol_weight'] != null ? (data['vol_weight'] as num).toDouble() : null,
        pieces: data['pieces'],
        amount: (data['amount'] as num).toDouble(),
        status: data['status1'],
        sender: data['sender'],
      );

      setState(() {
        submittedPod = pod;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ POD $podNumberDisplay submitted successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to submit data")));
      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  }

  @override
  void dispose() {
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

  Widget _buildFormSection(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff2a3368),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff2a3368),
        title: const Text(
          'New Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: sidebar(),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender & Receiver Section
                      _buildFormSection(
                        '👤 Sender & Receiver',
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AutocompleteTextField(
                                    hintText: 'Enter sender name',
                                    controller: _from,
                                    focusNode: _fromFocus,
                                    nextFocusNode: _toFocus,
                                    prefixIcon: Icons.person,
                                    suggestions: nameSuggestions,
                                    onSelected: (_) {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AutocompleteTextField(
                                    hintText: 'Enter receiver name',
                                    controller: _to,
                                    focusNode: _toFocus,
                                    nextFocusNode: _originFocus,
                                    prefixIcon: Icons.person,
                                    suggestions: nameSuggestions,
                                    onSelected: (_) {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Location Section
                      _buildFormSection(
                        '📍 Location Details',
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Origin:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 50,
                                    child: DropdownButtonFormField<String>(
                                      focusNode: _originFocus,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withOpacity(0.05),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      value: _origin,
                                      items: locationOptions.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _origin = newValue;
                                        });
                                        Future.delayed(const Duration(milliseconds: 100), () {
                                          FocusScope.of(context).requestFocus(_destinationFocus);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Destination:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 50,
                                    child: DropdownButtonFormField<String>(
                                      focusNode: _destinationFocus,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xff2a3368), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withOpacity(0.05),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      value: _destination,
                                      items: locationOptions.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _destination = newValue;
                                        });
                                        Future.delayed(const Duration(milliseconds: 100), () {
                                          FocusScope.of(context).requestFocus(_weightFocus);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Shipment Details Section
                      _buildFormSection(
                        '📦 Shipment Details',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contents:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => selected_doc = 'Documents'),
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: selected_doc == 'Documents' ? const Color(0xff2a3368) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: selected_doc == 'Documents' ? const Color(0xff2a3368) : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Documents',
                                                    style: TextStyle(
                                                      color: selected_doc == 'Documents' ? Colors.white : const Color(0xff2a3368),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => selected_doc = 'Non-Docx'),
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: selected_doc == 'Non-Docx' ? const Color(0xff2a3368) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: selected_doc == 'Non-Docx' ? const Color(0xff2a3368) : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Non-Docx',
                                                    style: TextStyle(
                                                      color: selected_doc == 'Non-Docx' ? Colors.white : const Color(0xff2a3368),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Weight (kg):',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      CommonTextField(
                                        hintText: 'e.g., 10.5',
                                        controller: _weight,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        focusNode: _weightFocus,
                                        prefixIcon: Icons.scale,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vol. Weight (kg):',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      CommonTextField(
                                        hintText: 'e.g., 8.75',
                                        controller: _volweight,
                                        focusNode: _volWeightFocus,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        prefixIcon: Icons.square_foot,
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pieces:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      CommonTextField(
                                        hintText: 'pcs',
                                        controller: _piece,
                                        focusNode: _pieceFocus,
                                        keyboardType: TextInputType.number,
                                        prefixIcon: Icons.inventory_2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Billing Section
                      _buildFormSection(
                        '💰 Billing',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rate (₹/kg):',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      CommonTextField(
                                        hintText: 'e.g., 50.75',
                                        controller: _rate,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        focusNode: _rateFocus,
                                        prefixIcon: Icons.currency_rupee,
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
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Amount:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16),
                                              child: Text(
                                                '₹ ${_amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xff2a3368),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (_weight.text.isEmpty || _rate.text.isEmpty) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("Please enter weight and rate")),
                                                    );
                                                    return;
                                                  }
                                                  final double weight = double.tryParse(_weight.text) ?? 0;
                                                  final double volWeight = double.tryParse(_volweight.text) ?? 0;
                                                  final double rate = double.tryParse(_rate.text) ?? 0;
                                                  if (volWeight == 0) {
                                                    _amount = weight * rate;
                                                  } else {
                                                    _amount = volWeight * rate;
                                                  }
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 16),
                                                child: Icon(Icons.calculate, color: Colors.blue.shade400, size: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Status & Sender Section
                      _buildFormSection(
                        '✅ Status & Sender',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => selected_status = 'Paid'),
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: selected_status == 'Paid' ? const Color(0xff2a3368) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: selected_status == 'Paid' ? const Color(0xff2a3368) : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Paid',
                                                    style: TextStyle(
                                                      color: selected_status == 'Paid' ? Colors.white : const Color(0xff2a3368),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => selected_status = 'Unpaid'),
                                              child: Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: selected_status == 'Unpaid' ? const Color(0xff2a3368) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: selected_status == 'Unpaid' ? const Color(0xff2a3368) : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'Unpaid',
                                                    style: TextStyle(
                                                      color: selected_status == 'Unpaid' ? Colors.white : const Color(0xff2a3368),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sender:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 50,
                                        child: DropdownButtonFormField<String>(
                                          focusNode: _senderFocus,
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(Icons.person, color: Colors.grey),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xff2a3368), width: 2),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.withOpacity(0.05),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          ),
                                          value: selectedOption,
                                          items: senderOptions.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedOption = newValue;
                                            });
                                            Future.delayed(const Duration(milliseconds: 100), () {
                                              FocusScope.of(context).requestFocus(_submitFocus);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xff2a3368), Color(0xff3d4a8a)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff2a3368).withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  focusNode: _submitFocus,
                                  onTap: () async {
                                    bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return Shortcuts(
                                          shortcuts: {
                                            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
                                            LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
                                          },
                                          child: Actions(
                                            actions: {
                                              ActivateIntent: CallbackAction<ActivateIntent>(
                                                onInvoke: (intent) {
                                                  Navigator.of(context).pop(true);
                                                  return null;
                                                },
                                              ),
                                              DismissIntent: CallbackAction<DismissIntent>(
                                                onInvoke: (intent) {
                                                  Navigator.of(context).pop(false);
                                                  return null;
                                                },
                                              ),
                                            },
                                            child: Focus(
                                              autofocus: true,
                                              child: AlertDialog(
                                                title: const Text("Are you sure?"),
                                                content: const Text("Do you want to submit this data?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text("No"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text("Yes"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    if (confirm ?? false) {
                                      submitPodData();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: const Center(
                                    child: Text(
                                      'Submit POD',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.purple.shade900,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade900.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: submittedPod == null
                                      ? null
                                      : () => generateAndPreviewInvoice(context, submittedPod!),
                                  borderRadius: BorderRadius.circular(14),
                                  child: const Center(
                                    child: Text(
                                      'Preview Invoice',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}