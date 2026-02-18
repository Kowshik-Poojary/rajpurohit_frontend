import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajpurohit/sidebar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'EditPaymentStatusManualPage.dart';
import 'EditVolWeightManualPage.dart';
import 'config/api.dart';
import 'pod_data.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class PreviousManualPodData extends StatefulWidget {
  const PreviousManualPodData({super.key});

  @override
  State<PreviousManualPodData> createState() => _PreviousManualPodDataState();
}

class _PreviousManualPodDataState extends State<PreviousManualPodData> {
  List<PodData> podList = [];
  bool isLoading = true;
  List<PodData> filteredList = [];
  TextEditingController originController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  TextEditingController idController = TextEditingController();
  final ScrollController _verticalScrollController = ScrollController();
  DateTime? startDate;
  DateTime? endDate;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchManualPods();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    originController.dispose();
    destinationController.dispose();
    fromController.dispose();
    toController.dispose();
    idController.dispose();
    super.dispose();
  }

  Future<void> fetchManualPods() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/get-manual-pods");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          podList = jsonData.map((json) => PodData.fromJson(json)).toList();
          isLoading = false;
        });
        filterTable();
      } else {
        print("Failed to load manual pods");
        setState(() => isLoading = false);
        _showErrorSnackbar("Failed to load manual POD data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
      _showErrorSnackbar("Error loading data: $e");
    }
  }

  void filterTable() {
    setState(() {
      filteredList = podList.where((pod) {
        bool matchesOrigin = originController.text.isEmpty ||
            pod.origin.toLowerCase().contains(originController.text.toLowerCase());
        bool matchesDestination = destinationController.text.isEmpty ||
            pod.destination.toLowerCase().contains(destinationController.text.toLowerCase());
        bool matchesFrom = fromController.text.isEmpty ||
            pod.from.toLowerCase().contains(fromController.text.toLowerCase());
        bool matchesTo = toController.text.isEmpty ||
            pod.to.toLowerCase().contains(toController.text.toLowerCase());
        bool matchesID = idController.text.isEmpty ||
            pod.podNumber.toString().contains(idController.text);
        bool matchesStatus =
            selectedStatus == null || selectedStatus == 'All' || pod.status == selectedStatus;

        bool matchesDate = true;
        if (startDate != null && endDate != null && pod.formattedDate.isNotEmpty) {
          try {
            final podDate = DateFormat('dd-MM-yyyy').parse(pod.formattedDate);
            matchesDate = podDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
                podDate.isBefore(endDate!.add(Duration(days: 1)));
          } catch (e) {
            matchesDate = false;
          }
        }

        return matchesOrigin &&
            matchesDestination &&
            matchesFrom &&
            matchesTo &&
            matchesID &&
            matchesStatus &&
            matchesDate;
      }).toList();
    });
  }

  Future<void> pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData(primaryColor: Color(0xff2a3368)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      filterTable();
    }
  }

  Future<void> exportFilteredToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Manual POD Data'];

    sheet.appendRow([
      'POD No.',
      'Date',
      'From',
      'To',
      'Origin',
      'Destination',
      'Doc',
      'Weight',
      'Vol Weight',
      'Pieces',
      'Amount',
      'Status',
      'Sender'
    ]);

    for (var pod in filteredList) {
      sheet.appendRow([
        pod.podNumber,
        pod.formattedDate,
        pod.from,
        pod.to,
        pod.origin,
        pod.destination,
        pod.doc,
        pod.weight,
        pod.volWeight,
        pod.pieces,
        pod.amount,
        pod.status,
        pod.sender,
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/manual_pod_data.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    final result = await OpenFile.open(path);

    if (result.type != ResultType.done) {
      _showErrorSnackbar('Failed to open file. Please install Excel app.');
    } else {
      _showSuccessSnackbar('Exported successfully!');
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      var storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ─── PDF Generation ───────────────────────────────────────────────────────

  Future<String> _fetchAddress() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/get-address'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address'] ?? 'No address found';
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
    return 'No address found';
  }

  pw.Widget _buildInvoice(PodData pod, pw.ImageProvider image, String address) {
    // Safely parse weight and volWeight from String fields
    final int weightInt = int.tryParse(pod.weight) ?? 0;
    final int? volWeightInt = pod.volWeight.isNotEmpty ? int.tryParse(pod.volWeight) : null;

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
                  // Logo + Company name
                  pw.Container(
                    width: 160,
                    height: 80,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
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
                  // Address
                  pw.Container(
                    width: 120,
                    height: 80,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: pw.Text(address, style: pw.TextStyle(fontSize: 10)),
                  ),
                  // Date + AWB
                  pw.Container(
                    width: 140,
                    height: 80,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          width: 140,
                          height: 40,
                          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                  // Origin / Destination
                  pw.Container(
                    width: 140,
                    height: 80,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
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
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          child: pw.Text('Origin', style: pw.TextStyle(color: PdfColors.white)),
                        ),
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          child: pw.Text(pod.origin),
                        ),
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            color: PdfColor.fromInt(0xff2a3368),
                          ),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          child: pw.Text('Destination', style: pw.TextStyle(color: PdfColors.white)),
                        ),
                        pw.Container(
                          width: 140,
                          height: 20,
                          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          child: pw.Text(pod.destination),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // From / To
              pw.Row(
                children: [
                  pw.Container(
                    width: 280,
                    height: 60,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('From'),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          pod.from,
                          style: pw.TextStyle(fontSize: 15, color: PdfColor.fromInt(0xff2a3368)),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 280,
                    height: 60,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('To'),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          pod.to,
                          style: pw.TextStyle(fontSize: 15, color: PdfColor.fromInt(0xff2a3368)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Contents / Weight / Vol Weight / Pieces / Amount / Status
              pw.Row(
                children: [
                  _buildPdfColumn('Contents', pod.doc),
                  _buildPdfColumn('Weight', '$weightInt kg'),
                  _buildPdfColumn('Vol. Weight', volWeightInt != null ? '$volWeightInt kg' : '-'),
                  _buildPdfColumn('Pieces', pod.pieces),
                  _buildPdfColumn('Amount', pod.amount),
                  _buildPdfColumn('Status', pod.status),
                ],
              ),
              // Declaration + Sender + Receiving
              pw.Row(
                children: [
                  pw.Container(
                    width: 280,
                    height: 50,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'I/WE HEREBY DECLARE THAT THIS CONSIGNMENT DOES NOT CONTAIN ANY CASH, SHARE CERTIFICATES, BEARER CHEQUES, JEWELLERY, CONTRABAND, DRUGS, WEAPONS, EXPLOSIVES, OR ANY ITEM PROHIBITED UNDER THE LAWS AND REGULATIONS OF THE CENTRAL, STATE, OR LOCAL AUTHORITIES.',
                      style: pw.TextStyle(fontSize: 7, lineSpacing: 2, wordSpacing: 1),
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
                            pw.Text('Sender - ', style: pw.TextStyle(color: PdfColors.white)),
                            pw.Text(pod.sender, style: pw.TextStyle(color: PdfColors.white)),
                          ],
                        ),
                      ),
                      pw.Container(
                        width: 140,
                        height: 25,
                        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Sign - '),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 140,
                    height: 50,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Receiving Sign & Stamp', style: pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build a header+value column cell for the details row
  pw.Widget _buildPdfColumn(String header, String value) {
    return pw.Column(
      children: [
        pw.Container(
          width: 93.33,
          height: 30,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
            color: PdfColor.fromInt(0xff2a3368),
          ),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(header, style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
        ),
        pw.Container(
          width: 93.33,
          height: 30,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value),
        ),
      ],
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, PodData pod, String address) async {
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
                _buildInvoice(pod, image, address),
                if (index < 2) pw.Divider(),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> _printPod(BuildContext context, PodData pod) async {
    final address = await _fetchAddress();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xff2a3368),
            title: Text('POD-${pod.podNumber}', style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PdfPreview(
            build: (format) => _generatePdf(format, pod, address),
          ),
        ),
      ),
    );
  }

  // ─── Table ────────────────────────────────────────────────────────────────

  Widget buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith((states) => const Color(0xff2a3368)),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        dataRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade100),
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('POD No.')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('From')),
          DataColumn(label: Text('To')),
          DataColumn(label: Text('Origin')),
          DataColumn(label: Text('Destination')),
          DataColumn(label: Text('Doc')),
          DataColumn(label: Text('Weight')),
          DataColumn(label: Text('Vol Weight')),
          DataColumn(label: Text('Pieces')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Sender')),
          DataColumn(label: Text('Print POD')),
        ],
        rows: filteredList.map((pod) {
          return DataRow(cells: [
            DataCell(Text("POD-${pod.podNumber}")),
            DataCell(Text(pod.formattedDate)),
            DataCell(Text(pod.from)),
            DataCell(Text(pod.to)),
            DataCell(Text(pod.origin)),
            DataCell(Text(pod.destination)),
            DataCell(Text(pod.doc)),
            DataCell(Text(pod.weight)),
            DataCell(
              Row(
                children: [
                  Text(pod.volWeight),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    tooltip: 'Edit Vol Weight',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditVolWeightManualPage(
                            podId: pod.podNumber,
                            currentVolWeight: pod.volWeight,
                            weight: int.parse(pod.weight),
                          ),
                        ),
                      ).then((_) => fetchManualPods());
                    },
                  ),
                ],
              ),
            ),
            DataCell(Text(pod.pieces)),
            DataCell(Text(pod.amount)),
            DataCell(
              Row(
                children: [
                  Text(pod.status),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.purple, size: 20),
                    tooltip: 'Edit Payment Status',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPaymentStatusManualPage(
                            podId: pod.podNumber,
                            currentStatus: pod.status,
                          ),
                        ),
                      ).then((_) => fetchManualPods());
                    },
                  ),
                ],
              ),
            ),
            DataCell(Text(pod.sender)),
            // ── Print POD button ──────────────────────────────────────────
            DataCell(
              IconButton(
                icon: const Icon(Icons.print, color: Color(0xff2a3368)),
                tooltip: 'Print POD',
                onPressed: () => _printPod(context, pod),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff2a3368),
        title: const Text('Previous Manual POD Data', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: sidebar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : podList.isEmpty
          ? const Center(child: Text("No manual POD records found."))
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  controller: idController,
                  onChanged: (_) => filterTable(),
                  decoration: const InputDecoration(
                    labelText: 'Search by POD No.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: originController,
                      onChanged: (_) => filterTable(),
                      decoration: const InputDecoration(
                        labelText: 'Search Origin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: destinationController,
                      onChanged: (_) => filterTable(),
                      decoration: const InputDecoration(
                        labelText: 'Search Destination',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: fromController,
                      onChanged: (_) => filterTable(),
                      decoration: const InputDecoration(
                        labelText: 'Search From',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: toController,
                      onChanged: (_) => filterTable(),
                      decoration: const InputDecoration(
                        labelText: 'Search To',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selectedStatus ?? 'All',
                    items: ['All', 'Paid', 'Unpaid']
                        .map((status) => DropdownMenuItem(
                      child: Text(status),
                      value: status,
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedStatus = value);
                      filterTable();
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => pickDateRange(context),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Filter by Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2a3368),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  bool granted = await requestStoragePermission();
                  if (!granted) {
                    _showErrorSnackbar('Storage permission is required.');
                    return;
                  }
                  await exportFilteredToExcel();
                },
                icon: const Icon(Icons.download),
                label: const Text("Export to Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2a3368),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  thickness: 8,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    scrollDirection: Axis.vertical,
                    child: buildTable(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}