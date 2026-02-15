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
        border: OutlineInputBorder(),
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
        title: Text('New Data', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: sidebar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Container(
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30),
                            Row(
                              children: [
                                Text('   From :  ', style: TextStyle(fontSize: 20)),
                                SizedBox(
                                  height: 45,
                                  width: 250,
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
                                          // Call onEditingComplete which properly handles Autocomplete selection
                                          onEditingComplete();
                                          FocusScope.of(context).requestFocus(_toFocus);
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Name',
                                          border: OutlineInputBorder(),
                                        ),
                                      );
                                    },

                                  ),

                                ),
                              ],
                            ), //From name
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   To      :  ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(
                                  height: 45,
                                  width: 250,
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
                                          // Call onEditingComplete which properly handles Autocomplete selection
                                          onEditingComplete();
                                          FocusScope.of(context).requestFocus(_originFocus);
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Name',
                                          border: OutlineInputBorder(),
                                        ),
                                      );
                                    },

                                  ),




                                ),


                              ],
                            ), //To name
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text('   Origin : ', style: TextStyle(fontSize: 20)),
                                SizedBox(
                                  height: 55,
                                  width: 250,
                                  child: DropdownButtonFormField<String>(
                                    focusNode: _originFocus,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Origin',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

                                SizedBox(width: 20),
                              ],
                            ), //Origin
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   Destination : ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(
                                  height: 55,
                                  width: 250,
                                  child: DropdownButtonFormField<String>(
                                    focusNode: _destinationFocus,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Destination',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

                                SizedBox(width: 20),
                              ],
                            ), //Destination
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text('  Contents :', style: TextStyle(fontSize: 20)),
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 45,
                                      width: 125,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selected_doc = 'Documents';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selected_doc == 'Documents'
                                              ? Color(0xff2a3368)
                                              : Colors.white,
                                          foregroundColor: selected_doc == 'Documents'
                                              ? Colors.white
                                              : Color(0xff2a3368),
                                        ),
                                        child: Text('Documents'),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    SizedBox(
                                      height: 45,
                                      width: 125,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selected_doc = 'Non-Docx';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selected_doc == 'Non-Docx'
                                              ? Color(0xff2a3368)
                                              : Colors.white,
                                          foregroundColor: selected_doc == 'Non-Docx'
                                              ? Colors.white
                                              : Color(0xff2a3368),
                                        ),

                                        child: Text('Non-Docx '),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ), //Document
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   Weight   :  ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(
                                  height: 45,
                                  width: 75,
                                  child: CommonTextField(
                                    hintText: 'kg',
                                    controller: _weight,
                                    keyboardType: TextInputType.number,
                                    focusNode: _weightFocus,
                                  ),
                                ),
                              ],
                            ), //weight
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   Vol. Wt   :  ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(
                                  height: 45,
                                  width: 75,
                                  child: CommonTextField(
                                    hintText: 'kg',
                                    controller: _volweight,
                                    focusNode: _volWeightFocus,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ), //volumetric weight
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   Pieces    :  ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(
                                  height: 45,
                                  width: 75,
                                  child: CommonTextField(
                                    hintText: 'pcs',
                                    controller: _piece,
                                    focusNode: _pieceFocus,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ), //No. of pieces
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   Rate        :  ',
                                  style: TextStyle(fontSize: 20),
                                ),

                                SizedBox(
                                  height: 45,
                                  width: 150,
                                  child: TextField(
                                    controller: _rate,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    focusNode: _rateFocus,
                                    onSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_senderFocus);
                                    },
                                    decoration: InputDecoration(
                                      hintText: '₹',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 100),
                                SizedBox(
                                  height: 45,
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_weight.text.isEmpty ||
                                            _rate.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Please enter both weight and rate",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final int weight =
                                            int.tryParse(_weight.text) ?? 0;
                                        final int volWeight =
                                            int.tryParse(_volweight.text) ?? 0;
                                        final int rate =
                                            int.tryParse(_rate.text) ?? 0;

                                        if (volWeight == 0) {
                                          _amount = weight * rate;
                                        } else {
                                          _amount = volWeight * rate;
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade900,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Amount'),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      4,
                                    ),
                                  ),
                                  child: Text(
                                    '$_amount',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                SizedBox(width: 50),
                              ],
                            ), //Amount to be Paid
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '  Status      :  ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 45,
                                      width: 100,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selected_status = 'Paid';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selected_status == 'Paid'
                                              ? Color(0xff2a3368)
                                              : Colors.white,
                                          foregroundColor: selected_status == 'Paid'
                                              ? Colors.white
                                              : Color(0xff2a3368),
                                        ),
                                        child: Text('Paid'),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    SizedBox(
                                      height: 45,
                                      width: 100,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selected_status = 'Unpaid';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: selected_status == 'Unpaid'
                                              ? Color(0xff2a3368)
                                              : Colors.white,
                                          foregroundColor: selected_status == 'Unpaid'
                                              ? Colors.white
                                              : Color(0xff2a3368),
                                        ),

                                        child: Text('Unpaid'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ), //Payment Status
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '   Sender  :  ',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 225,
                                  child: DropdownButtonFormField<String>(
                                    focusNode: _senderFocus,
                                    decoration: InputDecoration(
                                      labelText: 'Select Sender',
                                      border: OutlineInputBorder(),
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

                                SizedBox(width: 20),
                              ],
                            ), //Sender
                            SizedBox(height: 25),
                            Row(
                              children: [
                                SizedBox(width: 100),
                                SizedBox(
                                  height: 50,
                                  width: 150,
                                  child: ElevatedButton(
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
                                    child: Text('Submit'),
                                  ),
                                ),

                              ],
                            ), //submit
                            SizedBox(height: 25),
                            Row(
                              children: [
                                SizedBox(width: 100),
                                SizedBox(
                                  height: 50,
                                  width: 150,
                                  child: ElevatedButton(
                                    onPressed: submittedPod == null
                                        ? null
                                        : () => generateAndPreviewInvoice(
                                      context,
                                      submittedPod!,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade900,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text('Preview'),
                                  ),
                                ),
                              ],
                            ), //Preview
                            SizedBox(height: 25),
                          ],
                        ),
                      ],
                    ),
                  ),]
              ),
            ),
          ),
        ),
      ),


    );
  }
}