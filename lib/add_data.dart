import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajpurohit/sidebar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey, KeyDownEvent;
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

import 'config/api.dart';

class PodData {
  final int podNumber;
  final String date;
  final String formattedDate;
  final String from;
  final String to;
  final String origin;
  final String destination;
  final String doc;
  final int weight;
  final int? volWeight;
  final int pieces;
  final int amount;
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

  const CommonTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
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

  int _amount = 0;
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
          appBar: AppBar(title: Text('Invoice Preview')),
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
                              pw.Text('${pod.podNumber}'),
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
                        child: pw.Text('${pod.amount}'),
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
        SnackBar(content: Text("⚠️ Please fill all required fields")),
      );
      return;
    }

    int? weight = int.tryParse(_weight.text.trim());
    int? rate = int.tryParse(_rate.text.trim());

    if (weight == null || rate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Please enter valid Values")));
      return;
    }

    final int volWeight = int.tryParse(_volweight.text) ?? 0;
    _amount = (volWeight == 0 ? weight : volWeight) * rate;

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
        SnackBar(content: Text("⚠️ Please fill all required fields")),
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
        "weight": int.tryParse(_weight.text) ?? 0,
        "vol_weight": _volweight.text.isEmpty
            ? null
            : int.tryParse(_volweight.text),
        "pieces": int.tryParse(_piece.text) ?? 0,
        "amount": int.tryParse(_amount.toString()) ?? 0,
        "status1": selected_status,
        "sender": selectedOption,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      PodData pod = PodData(
        podNumber: data['podNumber'],
        date: data['date1'],
        formattedDate: DateFormat(
          'd-MM-yyyy',
        ).format(DateTime.parse(data['date1'])),
        from: data['from1'],
        to: data['to1'],
        origin: data['origin'],
        destination: data['destination'],
        doc: data['doc'],
        weight: data['weight'],
        volWeight: data['vol_weight'],
        pieces: data['pieces'],
        amount: data['amount'],
        status: data['status1'],
        sender: data['sender'],
      );

      setState(() {
        submittedPod = pod;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Data submitted successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit data")));
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

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff2a3368),
        title: Text('New Data', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
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
                            'Shipment Details',
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
                                  fieldViewBuilder: (
                                      context,
                                      controller,
                                      focusNode,
                                      onEditingComplete,
                                      ) {
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
                                  fieldViewBuilder: (
                                      context,
                                      controller,
                                      focusNode,
                                      onEditingComplete,
                                      ) {
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
                                        setState(() {
                                          _origin = newValue;
                                        });

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
                                        setState(() {
                                          _destination = newValue;
                                        });

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
                                      setState(() {
                                        selected_doc = 'Documents';
                                      });
                                    },
                                  ),
                                  _buildToggleButton(
                                    label: 'Non-Documents',
                                    isSelected: selected_doc == 'Non-Docx',
                                    onPressed: () {
                                      setState(() {
                                        selected_doc = 'Non-Docx';
                                      });
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
                                      hintText: 'Enter weight',
                                      controller: _weight,
                                      keyboardType: TextInputType.number,
                                      focusNode: _weightFocus,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Vol. Weight (kg)',
                                    child: CommonTextField(
                                      hintText: 'Enter volumetric weight',
                                      controller: _volweight,
                                      focusNode: _volWeightFocus,
                                      keyboardType: TextInputType.number,
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
                                    label: 'Rate (₹)',
                                    child: TextField(
                                      controller: _rate,
                                      focusNode: _rateFocus,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) {
                                        FocusScope.of(context).requestFocus(_senderFocus);
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Enter rate',
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

                                          final int weight = int.tryParse(_weight.text) ?? 0;
                                          final int volWeight = int.tryParse(_volweight.text) ?? 0;
                                          final int rate = int.tryParse(_rate.text) ?? 0;

                                          if (volWeight == 0) {
                                            _amount = weight * rate;
                                          } else {
                                            _amount = volWeight * rate;
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
                                      '₹${_amount.toString()}',
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
                                      setState(() {
                                        selected_status = 'Paid';
                                      });
                                    },
                                  ),
                                  _buildToggleButton(
                                    label: 'Unpaid',
                                    isSelected: selected_status == 'Unpaid',
                                    onPressed: () {
                                      setState(() {
                                        selected_status = 'Unpaid';
                                      });
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
                                  setState(() {
                                    selectedOption = newValue;
                                  });

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
                                                  title: const Text("Confirm Submission"),
                                                  content: const Text("Are you sure you want to submit this shipment data?"),
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
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: submittedPod == null
                                        ? null
                                        : () => generateAndPreviewInvoice(
                                      context,
                                      submittedPod!,
                                    ),
                                    icon: Icon(Icons.preview),
                                    label: Text('Preview Invoice'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
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