import 'package:intl/intl.dart';

class PodData {
  final String podNumber;  // Changed from int to String to store "R12345"
  final String from;
  final String to;
  final String doc;
  final String weight;
  final String volWeight;
  final String pieces;
  final String amount;
  final String status;
  final String sender;
  final String origin;
  final String destination;
  final String formattedDate;

  PodData({
    required this.podNumber,
    required this.from,
    required this.to,
    required this.doc,
    required this.weight,
    required this.volWeight,
    required this.pieces,
    required this.amount,
    required this.status,
    required this.sender,
    required this.origin,
    required this.destination,
    required this.formattedDate,
  });

  factory PodData.fromJson(Map<String, dynamic> json) {
    String rawDate = json['date1'] ?? '';
    String formatted = '';
    if (rawDate.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(rawDate);
        formatted = DateFormat('dd-MM-yyyy').format(dt);
      } catch (e) {
        print("Date parse error: $e");
      }
    }

    // Handle POD number - can be int or String from backend
    String podNumber = '';
    dynamic podNum = json['podNumber'];

    if (podNum != null) {
      if (podNum is String) {
        // Already has format like "R12345"
        podNumber = podNum;
      } else if (podNum is int) {
        // Convert int to String with R prefix if not already there
        podNumber = 'R$podNum';
      } else {
        // Fallback to string conversion
        podNumber = podNum.toString();
        if (!podNumber.startsWith('R')) {
          podNumber = 'R$podNumber';
        }
      }
    }

    return PodData(
      podNumber: podNumber,
      from: json['from1'] ?? '',
      to: json['to1'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      doc: json['doc'] ?? '',
      weight: json['weight']?.toString() ?? '',
      volWeight: json['vol_weight']?.toString() ?? '',
      pieces: json['pieces']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      status: json['status1'] ?? '',
      sender: json['sender'] ?? '',
      formattedDate: formatted,
    );
  }
}