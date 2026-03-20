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
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';

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
  final ScrollController _horizontalScrollController = ScrollController();
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
    _horizontalScrollController.dispose();
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
            pod.podNumber.toString().contains(idController.text) ||
            pod.podNumber.toString().replaceAll('R', '').contains(idController.text);

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

  Future<void> _exportInvoiceToExcel({required String toAddress}) async {
    final excelFile = xl.Excel.createExcel();
    excelFile.delete('Sheet1');
    final xl.Sheet sheet = excelFile['Invoice'];

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
    }

    // ===== UPDATED: Changed font to Calibri throughout =====
    xl.CellStyle companyHeader({int size = 14}) => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      bold: true,
      fontSize: size,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: size == 16 ? xl.Border(borderStyle: xl.BorderStyle.Medium) : null,
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
    );

    xl.CellStyle subHeader({int size = 11}) => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      bold: true,
      fontSize: size,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
    );

    xl.CellStyle addressLabel() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      bold: true,
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Left,
      verticalAlign: xl.VerticalAlign.Top,
    );

    xl.CellStyle addressText() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Left,
      verticalAlign: xl.VerticalAlign.Top,
    );

    xl.CellStyle tableHeader() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      bold: true,
      fontSize: 11,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
    );

    xl.CellStyle dataCell() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    );

    xl.CellStyle dataCellLeft() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Left,
      verticalAlign: xl.VerticalAlign.Center,
      topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    );

    xl.CellStyle plain({xl.HorizontalAlign align = xl.HorizontalAlign.Left, bool bold = false}) =>
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
          bold: bold,
          fontSize: 10,
          horizontalAlign: align,
          verticalAlign: xl.VerticalAlign.Center,
          leftBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
          rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
        );

    // ===== UPDATED: Clean footer borders - labels have NO borders, only values have right border =====
    xl.CellStyle footerLabel() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      bold: true,
      fontSize: 11,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      // NO BORDERS on labels
    );

    xl.CellStyle footerValue() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium), // Only right border
    );

    xl.CellStyle footerValueBold() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      bold: true,
      fontSize: 12,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium), // Only right border
    );

    xl.CellStyle signatureStyle() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
    );

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

    final List<Map<String, dynamic>> headerLines = [
      {'text': 'JOGSINGH A. RAJPUROHIT', 'bold': true, 'size': 16},
      {'text': 'OTC SERVICE DAILY – MUMBAI TO C. Sambhajinagar-AHAMAD NAGAR - Pune', 'bold': true, 'size': 12},
      {'text': 'Office : 307,Ganesh Society,Gautam Nagar', 'bold': false, 'size': 10},
      {'text': 'GSTIN:27BUXPS4675M1ZA        Andheri[E], Mumbai400093', 'bold': false, 'size': 10},
      {'text': 'PAN No. BUXPS4675M', 'bold': false, 'size': 10},
    ];
    for (int i = 0; i < headerLines.length; i++) {
      mergeRange(0, i, 7, i);
      if (i == 0) {
        setText(0, i, headerLines[i]['text'] as String, companyHeader(size: 16));
      } else if (i == 1) {
        setText(0, i, headerLines[i]['text'] as String, subHeader(size: 12));
      } else {
        setText(0, i, headerLines[i]['text'] as String, subHeader(size: 10));
      }
    }

    mergeRange(0, 5, 1, 5);
    setText(0, 5, 'To, ', plain());

    // ===== UPDATED: Align Bill No. to the right =====
    mergeRange(6, 5, 7, 5);
    setText(6, 5, 'BILL NO. :', plain(align: xl.HorizontalAlign.Right));

    final List<String> toLines = toAddress.split('\n');
    for (int i = 0; i < 4; i++) {
      mergeRange(0, 6 + i, 5, 6 + i);
      setText(0, 6 + i, i < toLines.length ? toLines[i] : '', plain(bold: i == 0));
    }

    final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    mergeRange(6, 6, 7, 6);
    setText(6, 6, 'Date: $today', plain(bold: true, align: xl.HorizontalAlign.Right));

    const int headerRowIdx = 10;
    // ===== UPDATED: Changed columns from "From, To" to "Origin, Destination" =====
    const List<String> cols = ['Sr. No.', 'Date', 'POD No.', 'Origin', 'Destination', 'Weight', 'BAG', 'Amount'];
    for (int c = 0; c < cols.length; c++) {
      setText(c, headerRowIdx, cols[c], tableHeader());
    }

    const int dataStartIdx = 11;
    for (int i = 0; i < filteredList.length; i++) {
      final PodData pod = filteredList[i];
      final int r = dataStartIdx + i;

      setInt(0, r, i + 1, dataCell());
      setText(1, r, pod.formattedDate, dataCell());
      setText(2, r, pod.podNumber.toString(), dataCell());
      // ===== UPDATED: Use origin and destination instead of from and to =====
      setText(3, r, pod.origin, dataCellLeft());
      setText(4, r, pod.destination, dataCellLeft());
      setInt(5, r, int.tryParse(pod.weight) ?? 0, dataCell());
      setInt(6, r, int.tryParse(pod.pieces) ?? 0, dataCell());
      setInt(7, r, int.tryParse(pod.amount) ?? 0, dataCell());
    }

    final int dataEndIdx = dataStartIdx + filteredList.length - 1;
    int fRow = dataEndIdx + 1;

    int totalAmount = 0;
    for (var pod in filteredList) {
      totalAmount += int.tryParse(pod.amount) ?? 0;
    }

    // ===== UPDATED: Calculate CGST and SGST without rounding =====
    double cgstAmount = (totalAmount * 9) / 100;
    double sgstAmount = (totalAmount * 9) / 100;

    // ===== UPDATED: Only round the total amount =====
    double subtotal = totalAmount + cgstAmount + sgstAmount;
    int totalAmountRounded = subtotal.round();

    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'Amount', footerLabel());
    setInt(7, fRow, totalAmount, footerValue());
    fRow++;

    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'CGST 9%', footerLabel());
    // ===== UPDATED: Display CGST as decimal =====
    final cell1 = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: fRow));
    cell1.value = xl.DoubleCellValue(cgstAmount);
    cell1.cellStyle = footerValue();
    fRow++;

    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'SGST 9%', footerLabel());
    // ===== UPDATED: Display SGST as decimal =====
    final cell2 = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: fRow));
    cell2.value = xl.DoubleCellValue(sgstAmount);
    cell2.cellStyle = footerValue();
    fRow++;

    mergeRange(5, fRow, 6, fRow);
    setText(5, fRow, 'Total Amount',
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
          bold: true,
          fontSize: 12,
          horizontalAlign: xl.HorizontalAlign.Right,
          verticalAlign: xl.VerticalAlign.Center,
          leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
          rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
          topBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
          bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
        ));
    setInt(7, fRow, totalAmountRounded, footerValueBold());
    fRow += 2;

    setText(7, fRow, 'Yours Truly,', xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      // NO BORDERS
    ));
    fRow++;

    final lastRow = fRow;
    final lastSignatureStyle = xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Right,
      verticalAlign: xl.VerticalAlign.Center,
      rightBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
      bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Medium),
    );
    setText(7, lastRow, 'For Jogsingh A. Rajpurohit', lastSignatureStyle);
    fRow += 2;

    try {
      final String saveDir = await _getSaveDirectory();
      final String dateStamp = DateFormat('dd-MM-yyyy_HHmmss').format(DateTime.now());
      final String fileName = 'invoice_$dateStamp.xlsx';

      final directory = Directory(saveDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String filePath = path_path.join(saveDir, fileName);
      final file = File(filePath);
      await file.writeAsBytes(excelFile.encode()!);

      print('✅ Invoice saved to: $filePath');
      print('File exists: ${await file.exists()}');
      print('File size: ${(await file.stat()).size} bytes');

      _showSuccessSnackbar('Invoice saved to:\n$filePath\n\nOpening Excel...');

      await Future.delayed(const Duration(milliseconds: 1000));

      bool fileOpened = false;

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final result = await OpenFile.open(filePath);
          print('Attempt ${attempt + 1} - OpenFile result: ${result.type}, message: ${result.message}');

          if (result.type.toString() == 'ResultType.done') {
            print('✅ File opened successfully on attempt ${attempt + 1}');
            fileOpened = true;
            break;
          } else {
            print('⚠️ Attempt ${attempt + 1}: Could not open (${result.type})');
            if (result.message.toLowerCase().contains('no app found') ||
                result.message.isEmpty ||
                result.message.toLowerCase().contains('error')) {
              if (attempt == 2) {
                print('⚠️ Failed to open file - no suitable app found');
                _showErrorSnackbar(
                    'Excel app not found.\n\n'
                        'File saved at:\n$filePath\n\n'
                        'Please install Excel or LibreOffice Calc'
                );
              }
            }
          }

          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          print('Error on attempt ${attempt + 1}: $e');
          if (attempt == 2) {
            print('Failed to open file after 3 attempts');
          }
        }
      }

      if (fileOpened) {
        print('✅ SUCCESS: File saved and opened successfully');
      } else {
        print('⚠️ WARNING: File saved but could not auto-open');
        print('File path: $filePath');
        _showSuccessSnackbar(
            'File saved successfully at:\n$filePath\n\n'
                'Please open manually or install Excel app.'
        );
      }
    } catch (e) {
      _showErrorSnackbar('Export failed: $e');
      print('❌ Export error: $e');
      print('Stack trace: ${e.toString()}');
    }
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final androidVersion = androidInfo.version.sdkInt;

        print('📱 Android SDK Version: $androidVersion');

        if (androidVersion >= 33) {
          print('🔄 Requesting Android 13+ permissions...');

          var manageExternal = await Permission.manageExternalStorage.request();

          if (manageExternal.isGranted) {
            print('✅ MANAGE_EXTERNAL_STORAGE granted (Full access)');
            return true;
          }

          if (manageExternal.isDenied) {
            print('⚠️ Trying scoped storage approach...');
            var photos = await Permission.photos.request();
            var videos = await Permission.videos.request();

            if (photos.isGranted || videos.isGranted) {
              print('✅ Scoped storage granted (Photos/Videos)');
              return true;
            }
          }

          if (manageExternal.isPermanentlyDenied) {
            print('❌ Permission permanently denied');
            _showStoragePermissionDialog();
            return false;
          }
        } else if (androidVersion >= 21) {
          print('🔄 Requesting Android 6-12 permissions...');

          var storage = await Permission.storage.request();

          if (storage.isGranted) {
            print('✅ WRITE_EXTERNAL_STORAGE granted');
            return true;
          }

          if (storage.isDenied) {
            print('⚠️ Storage permission denied (user can retry)');
            _showStoragePermissionDialog();
            return false;
          }

          if (storage.isPermanentlyDenied) {
            print('❌ Storage permission permanently denied');
            _showStoragePermissionDialog();
            return false;
          }
        } else {
          print('✅ Android 5 and below - no runtime permissions needed');
          return true;
        }

      } catch (e) {
        print('❌ Error checking permissions: $e');
        _showErrorSnackbar('Permission error: $e');
        return false;
      }
    }

    print('✅ Non-Android platform - permissions granted');
    return true;
  }

  void _showStoragePermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.folder_off, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Storage Permission Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This app needs permission to save Excel files to your Downloads folder.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to fix:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _buildStepText('1', 'Go to Settings'),
                    _buildStepText('2', 'Tap "Apps" or "Application Manager"'),
                    _buildStepText('3', 'Find and tap "Rajpurohit"'),
                    _buildStepText('4', 'Tap "Permissions" or "App Permissions"'),
                    _buildStepText('5', 'Tap "Files and media" or "Storage"'),
                    _buildStepText('6', 'Select "Allow" (or "Allow all files" if available)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'After granting permission, return to the app and try exporting again.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2a3368),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepText(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$step. $text',
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
                        pw.Text(pod.podNumber.toString()),
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
            title: Text(pod.podNumber.toString(),
                style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PdfPreview(
              build: (format) => _generatePdf(format, pod, address)),
        ),
      ),
    );
  }

  int _extractPodNumber(dynamic podNumber) {
    String str = podNumber.toString();
    if (str.startsWith('R')) {
      str = str.substring(1);
    }
    return int.tryParse(str) ?? 0;
  }

  Widget buildSearchField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onChanged,
  }) {
    return Flexible(
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xff2a3368), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            borderSide: const BorderSide(color: Color(0xff2a3368), width: 2),
          ),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      child: DataTable(
        headingRowColor:
        MaterialStateColor.resolveWith((states) => const Color(0xff2a3368)),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        dataRowColor:
        MaterialStateColor.resolveWith((states) => Colors.white),
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
          DataColumn(label: Text('Print')),
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
              DataCell(Text(pod.podNumber.toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
              DataCell(Text(pod.formattedDate, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.from, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.to, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.origin, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.destination, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.doc, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.weight, style: const TextStyle(fontSize: 12))),
              DataCell(
                Row(
                  children: [
                    Text(pod.volWeight, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 16),
                        tooltip: 'Edit Vol Weight',
                        onPressed: () {
                          int podId = _extractPodNumber(pod.podNumber);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditVolWeightManualPage(
                                podId: podId,
                                currentVolWeight: pod.volWeight,
                                weight: int.parse(pod.weight),
                              ),
                            ),
                          ).then((_) => fetchManualPods());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(pod.pieces, style: const TextStyle(fontSize: 12))),
              DataCell(Text(pod.amount, style: const TextStyle(fontSize: 12))),
              DataCell(
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_outlined, color: Colors.purple, size: 16),
                        tooltip: 'Edit Payment Status',
                        onPressed: () {
                          int podId = _extractPodNumber(pod.podNumber);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPaymentStatusManualPage(
                                podId: podId,
                                currentStatus: pod.status,
                              ),
                            ),
                          ).then((_) => fetchManualPods());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(pod.sender, style: const TextStyle(fontSize: 12))),
              DataCell(
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.print_outlined, color: Color(0xff2a3368), size: 18),
                    tooltip: 'Print POD',
                    onPressed: () => _printPod(context, pod),
                  ),
                ),
              ),
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
        title: const Text('Previous Manual POD Data',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
            Text("No manual POD records found.", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search & Filter',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff2a3368)),
                      ),
                      const SizedBox(height: 16),

                      buildSearchField(
                        controller: idController,
                        label: 'Search by POD No. (e.g., R123 or 123)',
                        onChanged: filterTable,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          buildSearchField(
                            controller: originController,
                            label: 'Origin',
                            onChanged: filterTable,
                          ),
                          const SizedBox(width: 12),
                          buildSearchField(
                            controller: destinationController,
                            label: 'Destination',
                            onChanged: filterTable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          buildSearchField(
                            controller: fromController,
                            label: 'From',
                            onChanged: filterTable,
                          ),
                          const SizedBox(width: 12),
                          buildSearchField(
                            controller: toController,
                            label: 'To',
                            onChanged: filterTable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: selectedStatus ?? 'All',
                                underline: const SizedBox(),
                                items: ['All', 'Paid', 'Unpaid']
                                    .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status, style: const TextStyle(fontSize: 13)),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => selectedStatus = value);
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _promptAndExport,
                              icon: const Icon(Icons.file_download, size: 18),
                              label: const Text('Export Invoice'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Records: ${filteredList.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),

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