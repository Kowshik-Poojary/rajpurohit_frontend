import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajpurohit/sidebar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'EditVolWeightPage.dart';
import 'config/api.dart';
import 'pod_data.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:excel/excel.dart';
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
  DateTime? startDate;
  DateTime? endDate;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchPods();
  }


  Future<void> fetchPods() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/get-all-pods"); // ✅ update IP as needed
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
        bool matchesID = idController.text.isEmpty || pod.id.contains(idController.text);

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

    // Add header
    sheet.appendRow([
      'ID', 'Date', 'From', 'To', 'Origin', 'Destination',
      'Doc', 'Weight', 'Vol Weight', 'Pieces', 'Amount', 'Status', 'Sender'
    ]);

    // Add data
    for (var pod in filteredList) {
      sheet.appendRow([
        pod.id,
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

    // Save to application directory
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/filtered_pod_data.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    // Open the Excel file using the default app
    final result = await OpenFile.open(path);

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open file. Please install Excel app.')),
      );
    }
  }
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;

      // Android 13+ (API 33 and above)
      if (Platform.version.contains('13') || Platform.version.contains('14')) {
        var audio = await Permission.audio.request();
        var video = await Permission.videos.request();
        var images = await Permission.photos.request();

        return audio.isGranted || video.isGranted || images.isGranted;
      }

      // For older Android versions
      var storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }





  Widget buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith((states) => const Color(0xff2a3368)),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        dataRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade100),
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('ID')),
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
          return DataRow(cells: [
            DataCell(Text(pod.id)),
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
                    icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                    tooltip: 'Edit Vol Weight',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditVolWeightPage(
                            podId: int.parse(pod.id),
                            currentVolWeight: pod.volWeight,
                            weight: int.parse(pod.weight), // ⬅️ pass original weight
                          ),
                        ),
                      ).then((_) => fetchPods());
                      // Refresh after update
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
                    icon: Icon(Icons.edit, color: Colors.purple, size: 20),
                    tooltip: 'Edit Payment Status',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPaymentStatusPage(
                            podId: int.parse(pod.id),
                            currentStatus: pod.status,
                          ),
                        ),
                      ).then((_) => fetchPods());// refresh after returning
                    },
                  ),
                ],
              ),
            ),

            DataCell(Text(pod.sender)),
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
        title: const Text('Previous Data', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: sidebar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : podList.isEmpty
          ? const Center(child: Text("No records found."))
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
                  decoration: InputDecoration(
                    labelText: 'Search by ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 12,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: originController,
                      onChanged: (_) => filterTable(),
                      decoration: InputDecoration(
                        labelText: 'Search Origin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20,),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: destinationController,
                      onChanged: (_) => filterTable(),
                      decoration: InputDecoration(
                        labelText: 'Search Destination',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                ],
              ),
              SizedBox(height: 12,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: fromController,
                      onChanged: (_) => filterTable(),
                      decoration: InputDecoration(
                        labelText: 'Search From',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20,),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: toController,
                      onChanged: (_) => filterTable(),
                      decoration: InputDecoration(
                        labelText: 'Search To',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12,),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: selectedStatus ?? 'All',
                    items: ['All','Paid', 'Unpaid']
                        .map((status) => DropdownMenuItem(
                      child: Text(status),
                      value: status,
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Storage permission is required.')),
                    );
                    return;
                  }

                  // Proceed to export and open the Excel file
                  await exportFilteredToExcel();
                },

                icon: Icon(Icons.download),
                label: Text("Export to Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2a3368),
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 12),

              Expanded(
                child: Scrollbar(
                  thickness: 8,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
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
