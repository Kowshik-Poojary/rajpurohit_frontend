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

  Future<void> _exportInvoiceToExcel({required String toAddress}) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final Sheet sheet = excel['Invoice'];

    // ── Column widths (A–H = indices 0–7) ────────────────────────────────
    sheet.setColWidth(0, 6.3);
    sheet.setColWidth(1, 12.4);
    sheet.setColWidth(2, 9.1);
    sheet.setColWidth(3, 16.6);
    sheet.setColWidth(4, 17.0);
    sheet.setColWidth(5, 8.7);
    sheet.setColWidth(6, 8.0);
    sheet.setColWidth(7, 9.4);

    // ── Shared style helpers ──────────────────────────────────────────────
    CellStyle centeredBold({int size = 11}) => CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      fontSize: size,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle plain({HorizontalAlign align = HorizontalAlign.Left, bool bold = false}) =>
        CellStyle(
          fontFamily: getFontFamily(FontFamily.Arial),
          bold: bold,
          fontSize: 11,
          horizontalAlign: align,
          verticalAlign: VerticalAlign.Center,
        );

    CellStyle bordered({HorizontalAlign align = HorizontalAlign.Center, bool bold = false}) =>
        CellStyle(
          fontFamily: getFontFamily(FontFamily.Arial),
          bold: bold,
          fontSize: 11,
          horizontalAlign: align,
          verticalAlign: VerticalAlign.Center,
          topBorder: Border(borderStyle: BorderStyle.Thin),
          bottomBorder: Border(borderStyle: BorderStyle.Thin),
          leftBorder: Border(borderStyle: BorderStyle.Thin),
          rightBorder: Border(borderStyle: BorderStyle.Thin),
        );

    CellStyle tableHeader() => CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: '#D9D9D9',
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle footerLabel() => CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle footerValue() => CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Shorthand: set a cell value + style
    void setCell(int col, int row, CellValue value, CellStyle style) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.value = value;
      cell.cellStyle = style;
    }

    void mergeRange(int colStart, int rowStart, int colEnd, int rowEnd) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: rowStart),
        CellIndex.indexByColumnRow(columnIndex: colEnd, rowIndex: rowEnd),
      );
    }

    // ── Rows 0–4: Company header (merged A:H) ─────────────────────────────
    final List<({String text, bool bold, int size})> headerLines = [
      (text: 'JOGSINGH A. RAJPUROHIT', bold: true, size: 12),
      (text: 'OTC SERVICE DAILY – MUMBAI TO C. Sambhajinagar-AHAMAD NAGAR - Pune', bold: true, size: 11),
      (text: 'Office : 307,Ganesh Society,Gautam Nagar', bold: false, size: 11),
      (text: 'GSTIN:27BUXPS4675M1ZA        Andheri[E], Mumbai400093', bold: false, size: 11),
      (text: '                PAN No. BUXPS4675M', bold: false, size: 11),
    ];
    for (int i = 0; i < headerLines.length; i++) {
      mergeRange(0, i, 7, i);
      setCell(0, i, TextCellValue(headerLines[i].text),
          centeredBold(size: headerLines[i].size));
    }

    // ── Row 5: "To," / HSN CODE / BILL NO. ───────────────────────────────
    mergeRange(0, 5, 1, 5);
    setCell(0, 5, const TextCellValue('To, '), plain());

    mergeRange(3, 5, 5, 5);
    setCell(3, 5, const TextCellValue('HSN CODE:9968'), plain());

    mergeRange(6, 5, 7, 5);
    setCell(6, 5, const TextCellValue('BILL NO. :'), plain());

    // ── Rows 6–9: "To" address lines (left) + Date (right on row 6) ───────
    final List<String> toLines = toAddress.split('\n');
    for (int i = 0; i < 4; i++) {
      mergeRange(0, 6 + i, 5, 6 + i);
      setCell(
        0,
        6 + i,
        TextCellValue(i < toLines.length ? toLines[i] : ''),
        plain(bold: i == 0),
      );
    }

    // Date auto-filled on row 6 right side
    final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    mergeRange(6, 6, 7, 6);
    setCell(6, 6, TextCellValue('Date: $today'), plain(bold: true, align: HorizontalAlign.Right));

    // ── Row 10 (index): Table column headers ──────────────────────────────
    const int headerRowIdx = 10;
    const List<String> cols = ['Sr. No.', 'Date', 'POD No.', 'From', 'To', 'Weight', 'BAG', 'Amount'];
    for (int c = 0; c < cols.length; c++) {
      setCell(c, headerRowIdx, TextCellValue(cols[c]), tableHeader());
    }

    // ── Data rows (index 11 onwards) ─────────────────────────────────────
    const int dataStartIdx = 11; // 0-indexed
    for (int i = 0; i < filteredList.length; i++) {
      final PodData pod = filteredList[i];
      final int r = dataStartIdx + i;

      setCell(0, r, IntCellValue(i + 1), bordered());
      setCell(1, r, TextCellValue(pod.formattedDate), bordered());
      setCell(2, r, IntCellValue(pod.podNumber), bordered());
      setCell(3, r, TextCellValue(pod.from), bordered());
      setCell(4, r, TextCellValue(pod.to), bordered());
      setCell(5, r, IntCellValue(int.tryParse(pod.weight) ?? 0), bordered());
      setCell(6, r, IntCellValue(int.tryParse(pod.pieces) ?? 0), bordered());
      setCell(7, r, IntCellValue(int.tryParse(pod.amount) ?? 0),
          bordered(align: HorizontalAlign.Right));
    }

    // ── Footer (Excel rows are 1-indexed in formulas) ────────────────────
    final int dataEndIdx = dataStartIdx + filteredList.length - 1; // 0-indexed
    final int dataStartExcel = dataStartIdx + 1; // 1-indexed
    final int dataEndExcel = dataEndIdx + 1;

    int fRow = dataEndIdx + 1; // next 0-indexed row after data

    // Total Weight — spans E:F (indices 4:5)
    mergeRange(4, fRow, 5, fRow);
    setCell(4, fRow, const TextCellValue('Total Weight'), footerLabel());
    setCell(5, fRow, TextCellValue('=SUM(F$dataStartExcel:F$dataEndExcel)'), footerValue());
    fRow++;

    // Amount (sum of H column) — label spans F:G (5:6), value in H (7)
    mergeRange(5, fRow, 6, fRow);
    setCell(5, fRow, const TextCellValue('Amount'), footerLabel());
    final int amountExcel = fRow + 1; // 1-indexed Excel row for this amount cell
    setCell(7, fRow, TextCellValue('=SUM(H$dataStartExcel:H$dataEndExcel)'), footerValue());
    fRow++;

    // CGST 9%
    mergeRange(5, fRow, 6, fRow);
    setCell(5, fRow, const TextCellValue('CGST 9%'), footerLabel());
    final int cgstExcel = fRow + 1;
    setCell(7, fRow, TextCellValue('=H$amountExcel*9%'), footerValue());
    fRow++;

    // SGST 9%
    mergeRange(5, fRow, 6, fRow);
    setCell(5, fRow, const TextCellValue('SGST 9%'), footerLabel());
    final int sgstExcel = fRow + 1;
    setCell(7, fRow, TextCellValue('=H$amountExcel*9%'), footerValue());
    fRow++;

    // Roundup — CEILING rounds sub-total up to next whole number, then subtracts sub-total
    // to give only the rounding amount needed
    mergeRange(5, fRow, 6, fRow);
    setCell(5, fRow, const TextCellValue('Roundup'), footerLabel());
    final int roundupExcel = fRow + 1;
    setCell(
      7,
      fRow,
      TextCellValue(
          '=CEILING(H$amountExcel+H$cgstExcel+H$sgstExcel,1)'
              '-(H$amountExcel+H$cgstExcel+H$sgstExcel)'),
      footerValue(),
    );
    fRow++;

    // Total Amount (bold, double-bottom border)
    mergeRange(5, fRow, 6, fRow);
    setCell(5, fRow, const TextCellValue('Total Amount'),
        CellStyle(
          fontFamily: getFontFamily(FontFamily.Arial),
          bold: true,
          fontSize: 11,
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        ));
    setCell(
      7,
      fRow,
      TextCellValue('=SUM(H$amountExcel:H$roundupExcel)'),
      CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Double),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      ),
    );
    fRow += 2;

    // Yours Truly
    setCell(7, fRow, const TextCellValue('Yours Truly,'),
        plain(align: HorizontalAlign.Right));
    fRow++;

    setCell(7, fRow, const TextCellValue('For Jogsingh A. Rajpurohit'),
        plain(align: HorizontalAlign.Right));
    fRow += 4;

    setCell(7, fRow, const TextCellValue('Authorised Sign.'),
        plain(align: HorizontalAlign.Right));

    // ── Save and open ─────────────────────────────────────────────────────
    final directory = await getApplicationDocumentsDirectory();
    final String dateStamp = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final String path = '${directory.path}/invoice_$dateStamp.xlsx';
    await File(path).writeAsBytes(excel.encode()!);

    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      _showErrorSnackbar('Failed to open file. Please install an Excel app.');
    } else {
      _showSuccessSnackbar('Invoice exported successfully!');
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