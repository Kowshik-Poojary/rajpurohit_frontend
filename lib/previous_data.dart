import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajpurohit/sidebar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'EditVolWeightPage.dart';
import 'config/api.dart';
import 'pod_data.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'edit_payment_status.dart';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

class previous_data extends StatefulWidget {
  const previous_data({super.key});

  @override
  State<previous_data> createState() => _previous_dataState();
}

class _previous_dataState extends State<previous_data> {
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
    fetchPods();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> fetchPods() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/get-all-pods");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        podList = jsonData.map((json) => PodData.fromJson(json)).toList();
        isLoading = false;
      });
      filterTable();
    } else {
      print("Failed to load data");
      setState(() => isLoading = false);
    }
  }

  void filterTable() {
    setState(() {
      filteredList = podList.where((pod) {
        bool matchesOrigin = originController.text.isEmpty || pod.origin.toLowerCase().contains(originController.text.toLowerCase());
        bool matchesDestination = destinationController.text.isEmpty || pod.destination.toLowerCase().contains(destinationController.text.toLowerCase());
        bool matchesFrom = fromController.text.isEmpty || pod.from.toLowerCase().contains(fromController.text.toLowerCase());
        bool matchesTo = toController.text.isEmpty || pod.to.toLowerCase().contains(toController.text.toLowerCase());
        bool matchesID = idController.text.isEmpty || pod.podNumber.toString().contains(idController.text);
        bool matchesStatus = selectedStatus == null || selectedStatus == 'All' || pod.status == selectedStatus;

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

        return matchesOrigin && matchesDestination && matchesFrom && matchesTo && matchesID && matchesStatus && matchesDate;
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
    Sheet sheet = excel['Filtered POD'];

    sheet.appendRow([
      TextCellValue('POD No.'),
      TextCellValue('Date'),
      TextCellValue('From'),
      TextCellValue('To'),
      TextCellValue('Origin'),
      TextCellValue('Destination'),
      TextCellValue('Doc'),
      TextCellValue('Weight'),
      TextCellValue('Vol Weight'),
      TextCellValue('Pieces'),
      TextCellValue('Amount'),
      TextCellValue('Status'),
      TextCellValue('Sender'),
    ]);

    for (var pod in filteredList) {
      sheet.appendRow([
        IntCellValue(pod.podNumber),
        TextCellValue(pod.formattedDate),
        TextCellValue(pod.from),
        TextCellValue(pod.to),
        TextCellValue(pod.origin),
        TextCellValue(pod.destination),
        TextCellValue(pod.doc),
        TextCellValue(pod.weight),
        TextCellValue(pod.volWeight),
        TextCellValue(pod.pieces),
        TextCellValue(pod.amount),
        TextCellValue(pod.status),
        TextCellValue(pod.sender),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/filtered_pod_data.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open file. Please install Excel app.')),
      );
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;

      if (Platform.version.contains('13') || Platform.version.contains('14')) {
        var audio = await Permission.audio.request();
        var video = await Permission.videos.request();
        var images = await Permission.photos.request();

        return audio.isGranted || video.isGranted || images.isGranted;
      }

      var storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  // Improved Search Field Widget
  Widget buildSearchField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xff2a3368), fontSize: 12),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xff2a3368), width: 2),
          ),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith((states) => const Color(0xff2a3368)),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        dataRowColor: MaterialStateColor.resolveWith((states) => Colors.white),
        columnSpacing: 16,
        horizontalMargin: 12,
        dataRowHeight: 56,
        headingRowHeight: 56,
        dividerThickness: 1,
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
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
        ],
        rows: filteredList.map((pod) {
          return DataRow(
            color: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.hovered)) {
                return Colors.grey.shade50;
              }
              return Colors.white;
            }),
            cells: [
              DataCell(Text("POD-${pod.podNumber}", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
              DataCell(Text(pod.formattedDate, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.from, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.to, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.origin, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.destination, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.doc, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.weight, style: TextStyle(fontSize: 12))),
              DataCell(
                Row(
                  children: [
                    Text(pod.volWeight, style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.edit_outlined, color: Colors.blue, size: 16),
                        tooltip: 'Edit Vol Weight',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditVolWeightPage(
                                podId: pod.podNumber,
                                currentVolWeight: pod.volWeight,
                                weight: int.parse(pod.weight),
                              ),
                            ),
                          ).then((_) => fetchPods());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(pod.pieces, style: TextStyle(fontSize: 12))),
              DataCell(Text(pod.amount, style: TextStyle(fontSize: 12))),
              DataCell(
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pod.status == 'Paid' ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pod.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: pod.status == 'Paid' ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.edit_outlined, color: Colors.purple, size: 16),
                        tooltip: 'Edit Payment Status',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPaymentStatusPage(
                                podId: pod.podNumber,
                                currentStatus: pod.status,
                              ),
                            ),
                          ).then((_) => fetchPods());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(pod.sender, style: TextStyle(fontSize: 12))),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff2a3368),
        title: const Text('Previous Data', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      drawer: sidebar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff2a3368)))
          : podList.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No records found.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Filter Cards
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search & Filter',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff2a3368)),
                      ),
                      SizedBox(height: 16),

                      // POD No. Search
                      buildSearchField(
                        controller: idController,
                        label: 'Search by POD No.',
                        onChanged: filterTable,
                      ),
                      SizedBox(height: 12),

                      // Origin & Destination
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          buildSearchField(
                            controller: originController,
                            label: 'Origin',
                            onChanged: filterTable,
                          ),
                          SizedBox(width: 12),
                          buildSearchField(
                            controller: destinationController,
                            label: 'Destination',
                            onChanged: filterTable,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // From & To
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          buildSearchField(
                            controller: fromController,
                            label: 'From',
                            onChanged: filterTable,
                          ),
                          SizedBox(width: 12),
                          buildSearchField(
                            controller: toController,
                            label: 'To',
                            onChanged: filterTable,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Status & Date Filters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: selectedStatus ?? 'All',
                              underline: SizedBox(),
                              items: ['All', 'Paid', 'Unpaid']
                                  .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status, style: TextStyle(fontSize: 13)),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value;
                                });
                                filterTable();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => pickDateRange(context),
                            icon: const Icon(Icons.date_range, size: 18),
                            label: const Text('Filter by Date'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2a3368),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              bool granted = await requestStoragePermission();
                              if (!granted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Storage permission is required.')),
                                );
                                return;
                              }
                              await exportFilteredToExcel();
                            },
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text("Export to Excel"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Records Count
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Records: ${filteredList.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: 8),

              // Table
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}