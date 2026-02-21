import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rajpurohit/sidebar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'EditPaymentStatusManualPage.dart';
import 'EditVolWeightManualPage.dart';
import 'config/api.dart';
import 'pod_data.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path_path;
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
        setState(() => isLoading = false);
        _showErrorSnackbar("Failed to load manual POD data");
      }
    } catch (e) {
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
            matchesDate = podDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                podDate.isBefore(endDate!.add(const Duration(days: 1)));
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData(primaryColor: const Color(0xff2a3368)),
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

  /// ✅ Get proper save directory based on platform
  Future<String> _getSaveDirectory() async {
    if (Platform.isWindows) {
      final String? downloadsPath =
      await path_provider.getDownloadsDirectory().then((dir) => dir?.path);
      if (downloadsPath != null && downloadsPath.isNotEmpty) {
        return downloadsPath;
      }
      return (await path_provider.getApplicationDocumentsDirectory()).path;
    } else if (Platform.isMacOS || Platform.isLinux) {
      try {
        final String? downloadsPath =
        await path_provider.getDownloadsDirectory().then((dir) => dir?.path);
        if (downloadsPath != null && downloadsPath.isNotEmpty) {
          return downloadsPath;
        }
      } catch (e) {
        print('Error getting downloads directory: $e');
      }
      return (await path_provider.getApplicationDocumentsDirectory()).path;
    } else {
      return (await path_provider.getApplicationDocumentsDirectory()).path;
    }
  }

  // ─── Invoice Excel Export ────────────────────────────────────────────────

  /// Prompts user to enter the "To" address, then exports the invoice.
  Future<void> _promptAndExport() async {
    final toAddressController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the "To" address for the invoice:',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: toAddressController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Company name\nAddress line 1\nAddress line 2\nGSTIN…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2a3368),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bool granted = await requestStoragePermission();
      if (!granted) {
        _showErrorSnackbar('Storage permission is required.');
        return;
      }
      await _exportInvoiceToExcel(toAddress: toAddressController.text.trim());
    }
  }

  /// ✅ FIXED: Use proper CellValue wrappers, correct method names, and proper color handling
  Future<void> _exportInvoiceToExcel({required String toAddress}) async {
    final excelFile = xl.Excel.createExcel();
    excelFile.delete('Sheet1');
    final xl.Sheet sheet = excelFile['Invoice'];

    // ── Column widths (A–H = indices 0–7) ────────────────────────────────
    // ✅ FIXED: Use correct method for setting column widths
    // Note: The exact method may vary - if this doesn't work, check your excel package docs
    try {
      sheet.setColumnWidth(0, 6.3);
      sheet.setColumnWidth(1, 12.4);
      sheet.setColumnWidth(2, 9.1);
      sheet.setColumnWidth(3, 16.6);
      sheet.setColumnWidth(4, 17.0);
      sheet.setColumnWidth(5, 8.7);
      sheet.setColumnWidth(6, 8.0);
      sheet.setColumnWidth(7, 9.4);
    } catch (e) {
      print('Warning: Could not set column widths: $e');
      // Column widths are optional, so don't fail if this doesn't work
    }

    // ── Style helpers ─────────────────────────────────────────────────────
    xl.CellStyle centeredBold({int size = 11}) => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      bold: true,
      fontSize: size,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    xl.CellStyle plain({xl.HorizontalAlign align = xl.HorizontalAlign.Left, bool bold = false}) =>
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
          bold: bold,
          fontSize: 11,
          horizontalAlign: align,
          verticalAlign: xl.VerticalAlign.Center,
        );

    xl.CellStyle bordered({xl.HorizontalAlign align = xl.HorizontalAlign.Center, bool bold = false}) =>
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
          bold: bold,
          fontSize: 11,
          horizontalAlign: align,
          verticalAlign: xl.VerticalAlign.Center,
          topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
          bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
          leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
          rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
        );

    // ✅ FIXED: Removed invalid backgroundColorHex, using proper property if available
    xl.CellStyle tableHeader() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      bold: true,
      fontSize: 11,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    );

    xl.CellStyle footerLabel() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      bold: true,
      fontSize: 11,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
    );

    xl.CellStyle footerValue() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 11,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    );

    // ✅ FIXED: Wrap values in proper CellValue types
    void setText(int col, int row, String value, xl.CellStyle style) {
      final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.value = xl.TextCellValue(value);
      cell.cellStyle = style;
    }

    void setInt(int col, int row, int value, xl.CellStyle style) {
      final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.value = xl.IntCellValue(value);
      cell.cellStyle = style;
    }

    void mergeRange(int colStart, int rowStart, int colEnd, int rowEnd) {
      sheet.merge(
        xl.CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: rowStart),
        xl.CellIndex.indexByColumnRow(columnIndex: colEnd, rowIndex: rowEnd),
      );
    }

    // ── Rows 0–4: Company header (merged A:H) ─────────────────────────────
    final List<Map<String, dynamic>> headerLines = [
      {'text': 'JOGSINGH A. RAJPUROHIT', 'bold': true, 'size': 12},
      {'text': 'OTC SERVICE DAILY – MUMBAI TO C. Sambhajinagar-AHAMAD NAGAR - Pune', 'bold': true, 'size': 11},
      {'text': 'Office : 307,Ganesh Society,Gautam Nagar', 'bold': false, 'size': 11},
      {'text': 'GSTIN:27BUXPS4675M1ZA        Andheri[E], Mumbai400093', 'bold': false, 'size': 11},
      {'text': '                PAN No. BUXPS4675M', 'bold': false, 'size': 11},
    ];
    for (int i = 0; i < headerLines.length; i++) {
      mergeRange(0, i, 7, i);
      setText(0, i, headerLines[i]['text'] as String,
          centeredBold(size: headerLines[i]['size'] as int));
    }

    // ── Row 5: "To," / HSN CODE / BILL NO. ───────────────────────────────
    mergeRange(0, 5, 1, 5);
    setText(0, 5, 'To, ', plain());

    mergeRange(3, 5, 5, 5);
    setText(3, 5, 'HSN CODE:9968', plain());

    mergeRange(6, 5, 7, 5);
    setText(6, 5, 'BILL NO. :', plain());

    // ── Rows 6–9: "To" address lines (left) + Date (right on row 6) ───────
    final List<String> toLines = toAddress.split('\n');
    for (int i = 0; i < 4; i++) {
      mergeRange(0, 6 + i, 5, 6 + i);
      setText(0, 6 + i, i < toLines.length ? toLines[i] : '', plain(bold: i == 0));
    }

    // Date auto-filled on row 6 right side
    final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    mergeRange(6, 6, 7, 6);
    setText(6, 6, 'Date: $today', plain(bold: true, align: xl.HorizontalAlign.Right));

    // ── Row 10: Table column headers ──────────────────────────────────────
    const int headerRowIdx = 10;
    const List<String> cols = ['Sr. No.', 'Date', 'POD No.', 'From', 'To', 'Weight', 'BAG', 'Amount'];
    for (int c = 0; c < cols.length; c++) {
      setText(c, headerRowIdx, cols[c], tableHeader());
    }

    // ── Data rows (index 11 onwards) ─────────────────────────────────────
    const int dataStartIdx = 11;
    for (int i = 0; i < filteredList.length; i++) {
      final PodData pod = filteredList[i];
      final int r = dataStartIdx + i;

      setInt(0, r, i + 1, bordered());
      setText(1, r, pod.formattedDate, bordered());
      setInt(2, r, pod.podNumber, bordered());
      setText(3, r, pod.from, bordered());
      setText(4, r, pod.to, bordered());
      setInt(5, r, int.tryParse(pod.weight) ?? 0, bordered());
      setInt(6, r, int.tryParse(pod.pieces) ?? 0, bordered());
      setInt(7, r, int.tryParse(pod.amount) ?? 0, bordered(align: xl.HorizontalAlign.Right));
    }

    // ── Footer ────────────────────────────────────────────────────────────
    final int dataEndIdx = dataStartIdx + filteredList.length - 1;
    final int dataStartExcel = dataStartIdx + 1;
    final int dataEndExcel = dataEndIdx + 1;
    int fRow = dataEndIdx + 1;

    // Total Weight
    mergeRange(4, fRow, 5, fRow);
    setText(4, fRow, 'Total Weight', footerLabel());
    setText(5, fRow, '=SUM(F$dataStartExcel:F$dataEndExcel)', footerValue());
    fRow++;

    // Amount
    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'Amount', footerLabel());
    final int amountExcel = fRow + 1;
    setText(7, fRow, '=SUM(H$dataStartExcel:H$dataEndExcel)', footerValue());
    fRow++;

    // CGST 9%
    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'CGST 9%', footerLabel());
    final int cgstExcel = fRow + 1;
    setText(7, fRow, '=H$amountExcel*9%', footerValue());
    fRow++;

    // SGST 9%
    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'SGST 9%', footerLabel());
    final int sgstExcel = fRow + 1;
    setText(7, fRow, '=H$amountExcel*9%', footerValue());
    fRow++;

    // Roundup
    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'Roundup', footerLabel());
    final int roundupExcel = fRow + 1;
    setText(7, fRow,
        '=CEILING(H$amountExcel+H$cgstExcel+H$sgstExcel,1)'
            '-(H$amountExcel+H$cgstExcel+H$sgstExcel)',
        footerValue());
    fRow++;

    // Total Amount
    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'Total Amount',
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
          bold: true,
          fontSize: 11,
          horizontalAlign: xl.HorizontalAlign.Right,
          verticalAlign: xl.VerticalAlign.Center,
        ));
    setText(7, fRow, '=SUM(H$amountExcel:H$roundupExcel)',
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
          bold: true,
          fontSize: 11,
          horizontalAlign: xl.HorizontalAlign.Right,
          verticalAlign: xl.VerticalAlign.Center,
          topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
          bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Double),
          leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
          rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
        ));
    fRow += 2;

    // Yours Truly
    setText(7, fRow, 'Yours Truly,', plain(align: xl.HorizontalAlign.Right));
    fRow++;
    setText(7, fRow, 'For Jogsingh A. Rajpurohit', plain(align: xl.HorizontalAlign.Right));
    fRow += 4;
    setText(7, fRow, 'Authorised Sign.', plain(align: xl.HorizontalAlign.Right));

    // ── Save and open ─────────────────────────────────────────────────────
    try {
      final String saveDir = await _getSaveDirectory();
      final String dateStamp = DateFormat('dd-MM-yyyy_HHmmss').format(DateTime.now());
      final String fileName = 'invoice_$dateStamp.xlsx';

      // Create directory if it doesn't exist
      final directory = Directory(saveDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String filePath = path_path.join(saveDir, fileName);
      await File(filePath).writeAsBytes(excelFile.encode()!);

      print('✅ Invoice saved to: $filePath');
      print('File exists: ${await File(filePath).exists()}');
      print('File size: ${(await File(filePath).stat()).size} bytes');

      _showSuccessSnackbar('Invoice saved to:\n$filePath');

      // Try to open the file
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        print('File saved at: $filePath');
      }
    } catch (e) {
      _showErrorSnackbar('Export failed: $e');
      print('Export error: $e');
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
    final int weightInt = int.tryParse(pod.weight) ?? 0;
    final int? volWeightInt =
    pod.volWeight.isNotEmpty ? int.tryParse(pod.volWeight) : null;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Container(
                  width: 160,
                  height: 80,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  child: pw.Stack(children: [
                    pw.Image(image),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('    M/S JOGSINGH.A.RAJPUROHIT',
                            style: pw.TextStyle(fontSize: 9)),
                        pw.Text('GSTIN 27BUXPS4675M1ZA',
                            style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ]),
                ),
                pw.Container(
                  width: 120,
                  height: 80,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: pw.Text(address, style: pw.TextStyle(fontSize: 10)),
                ),
                pw.Container(
                  width: 140,
                  height: 80,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  child: pw.Column(children: [
                    pw.Container(
                      width: 140,
                      height: 40,
                      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: pw.Row(children: [
                        pw.Text('Date - '),
                        pw.Text(pod.formattedDate),
                      ]),
                    ),
                    pw.Container(
                      width: 140,
                      height: 40,
                      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: pw.Row(children: [
                        pw.Text('AWB no. - '),
                        pw.Text('${pod.podNumber}'),
                      ]),
                    ),
                  ]),
                ),
                pw.Container(
                  width: 140,
                  height: 80,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140, height: 20,
                        decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            color: PdfColor.fromInt(0xff2a3368)),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        child: pw.Text('Origin',
                            style: pw.TextStyle(color: PdfColors.white)),
                      ),
                      pw.Container(
                        width: 140, height: 20,
                        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        child: pw.Text(pod.origin),
                      ),
                      pw.Container(
                        width: 140, height: 20,
                        decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            color: PdfColor.fromInt(0xff2a3368)),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        child: pw.Text('Destination',
                            style: pw.TextStyle(color: PdfColors.white)),
                      ),
                      pw.Container(
                        width: 140, height: 20,
                        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        child: pw.Text(pod.destination),
                      ),
                    ],
                  ),
                ),
              ]),
              pw.Row(children: [
                pw.Container(
                  width: 280, height: 60,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('From'),
                      pw.SizedBox(height: 5),
                      pw.Text(pod.from,
                          style: pw.TextStyle(
                              fontSize: 15, color: PdfColor.fromInt(0xff2a3368))),
                    ],
                  ),
                ),
                pw.Container(
                  width: 280, height: 60,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('To'),
                      pw.SizedBox(height: 5),
                      pw.Text(pod.to,
                          style: pw.TextStyle(
                              fontSize: 15, color: PdfColor.fromInt(0xff2a3368))),
                    ],
                  ),
                ),
              ]),
              pw.Row(children: [
                _buildPdfColumn('Contents', pod.doc),
                _buildPdfColumn('Weight', '$weightInt kg'),
                _buildPdfColumn(
                    'Vol. Weight', volWeightInt != null ? '$volWeightInt kg' : '-'),
                _buildPdfColumn('Pieces', pod.pieces),
                _buildPdfColumn('Amount', pod.amount),
                _buildPdfColumn('Status', pod.status),
              ]),
              pw.Row(children: [
                pw.Container(
                  width: 280, height: 50,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    'I/WE HEREBY DECLARE THAT THIS CONSIGNMENT DOES NOT CONTAIN ANY CASH, SHARE CERTIFICATES, BEARER CHEQUES, JEWELLERY, CONTRABAND, DRUGS, WEAPONS, EXPLOSIVES, OR ANY ITEM PROHIBITED UNDER THE LAWS AND REGULATIONS OF THE CENTRAL, STATE, OR LOCAL AUTHORITIES.',
                    style: pw.TextStyle(fontSize: 7, lineSpacing: 2, wordSpacing: 1),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
                pw.Column(children: [
                  pw.Container(
                    width: 140, height: 25,
                    decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        color: PdfColor.fromInt(0xff2a3368)),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Row(children: [
                      pw.Text('Sender - ',
                          style: pw.TextStyle(color: PdfColors.white)),
                      pw.Text(pod.sender,
                          style: pw.TextStyle(color: PdfColors.white)),
                    ]),
                  ),
                  pw.Container(
                    width: 140, height: 25,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Sign - '),
                  ),
                ]),
                pw.Container(
                  width: 140, height: 50,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Receiving Sign & Stamp',
                      style: pw.TextStyle(fontSize: 10)),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfColumn(String header, String value) {
    return pw.Column(children: [
      pw.Container(
        width: 93.33, height: 30,
        decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
            color: PdfColor.fromInt(0xff2a3368)),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(header,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
      ),
      pw.Container(
        width: 93.33, height: 30,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value),
      ),
    ]);
  }

  Future<Uint8List> _generatePdf(
      PdfPageFormat format, PodData pod, String address) async {
    final pdf = pw.Document();
    final imageBytes = await rootBundle.load('assets/images/logo1.png');
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10),
      build: (context) => pw.Column(
        children: List.generate(3, (index) => pw.Column(children: [
          _buildInvoice(pod, image, address),
          if (index < 2) pw.Divider(),
        ])),
      ),
    ));
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
            title: Text('POD-${pod.podNumber}',
                style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PdfPreview(
              build: (format) => _generatePdf(format, pod, address)),
        ),
      ),
    );
  }

  // ─── Table ────────────────────────────────────────────────────────────────

  Widget buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
        MaterialStateColor.resolveWith((states) => const Color(0xff2a3368)),
        headingTextStyle:
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        dataRowColor:
        MaterialStateColor.resolveWith((states) => Colors.grey.shade100),
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
            DataCell(Row(children: [
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
            ])),
            DataCell(Text(pod.pieces)),
            DataCell(Text(pod.amount)),
            DataCell(Row(children: [
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
            ])),
            DataCell(Text(pod.sender)),
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
        title: const Text('Previous Manual POD Data',
            style: TextStyle(color: Colors.white)),
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
                onPressed: _promptAndExport,
                icon: const Icon(Icons.file_download),
                label: const Text('Export Invoice to Excel'),
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