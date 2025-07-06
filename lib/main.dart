import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rajpurohit/login.dart';
import 'sidebar.dart';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

class OrderStats {
  final String date;
  final int orders;

  OrderStats({required this.date, required this.orders});

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      date: json['day'],
      orders: json['total_orders'],
    );
  }
}

class PaidUnpaidStats {
  final String date;
  final int paid;
  final int unpaid;

  PaidUnpaidStats({required this.date, required this.paid, required this.unpaid});

  factory PaidUnpaidStats.fromJson(Map<String, dynamic> json) {
    return PaidUnpaidStats(
      date: json['day'],
      paid: json['paid'],
      unpaid: json['unpaid'],
    );
  }
}


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rajpurohit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: login(),
      debugShowCheckedModeBanner: false,
    );
  }
}
class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {

  List<OrderStats> weeklyStats = [];
  List<PaidUnpaidStats> paidUnpaidList = [];

  Future<void> fetchPaidUnpaidStats() async {
    final response = await http.get(Uri.parse('https://rajpurohit-backend.onrender.com/paid-unpaid-stats'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        paidUnpaidList = data.map((e) => PaidUnpaidStats.fromJson(e)).toList();
      });
    } else {
      print('❌ Failed to fetch paid/unpaid stats');
    }
  }


  Future<void> fetchWeeklyOrders() async {
    final response = await http.get(Uri.parse('https://rajpurohit-backend.onrender.com/orders-per-day'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        weeklyStats = data.map((e) => OrderStats.fromJson(e)).toList();
      });
    } else {
      print('❌ Failed to fetch order stats');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeeklyOrders();
    fetchPaidUnpaidStats();
  }

  Widget buildPaidUnpaidBarChart() {
    if (paidUnpaidList.isEmpty) return Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade200,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Paid' : 'Unpaid';
              return BarTooltipItem(
                '$label: ${rod.toY.toInt()}',
                TextStyle(
                  color: rodIndex == 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= paidUnpaidList.length) return SizedBox();
                final date = DateTime.parse(paidUnpaidList[index].date);
                return Text("${date.day}/${date.month}", style: TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        gridData: FlGridData(show: false),
        barGroups: paidUnpaidList.asMap().entries.map((entry) {
          int index = entry.key;
          PaidUnpaidStats stat = entry.value;
          return BarChartGroupData(
            x: index,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: stat.paid.toDouble(),
                color: Colors.green,
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: stat.unpaid.toDouble(),
                color: Colors.red,
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
        maxY: paidUnpaidList.map((e) => (e.paid > e.unpaid ? e.paid : e.unpaid)).reduce((a, b) => a > b ? a : b).toDouble() + 2,
      ),
    );
  }


  Widget buildBarChart() {
    if (weeklyStats.isEmpty) return Center(child: Text('No data'));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height*0.55, // ~55% of screen
        width: double.infinity,
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.deepPurple.shade100, // ✅ background color
                tooltipBorder: BorderSide(color: Colors.purple.shade900, width: 1),
                tooltipPadding: EdgeInsets.all(8),
                tooltipMargin: 12,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} Orders',
                    TextStyle(
                      color: Colors.purple.shade900, // ✅ text color
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),

            alignment: BarChartAlignment.spaceAround,
            maxY: weeklyStats.map((e) => e.orders).reduce((a, b) => a > b ? a : b).toDouble() + 2,
            barGroups: weeklyStats.asMap().entries.map((entry) {
              int index = entry.key;
              OrderStats stat = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: stat.orders.toDouble(),
                    color: Colors.purple,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
            gridData: FlGridData(show: false), // Optional: hide grid lines
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // ✅ Hide right Y-axis
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Optional
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < 0 || index >= weeklyStats.length) return SizedBox();
                    final date = DateTime.parse(weeklyStats[index].date);
                    final label = "${date.day}/${date.month}";
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(label, style: TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
    appBar: AppBar(
      backgroundColor: Color(0xff2a3368),
      title: Text('HOME', style: TextStyle(color: Colors.white),),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),

    ),
      drawer: sidebar(),
      body: Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Welcome Text
                Text(
                  '👏 Welcome to RAJPUROHIT OTC SERVICE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2a3368),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // About Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'RAJPUROHIT OTC SERVICE is dedicated to providing reliable courier and logistics solutions across India. '
                          'With our commitment to speed, safety, and customer satisfaction, we aim to simplify every delivery experience.\n'
                      'Daily seemless Courier services take place within destinations - \n'
                      'Mumbai\n'
                      'Pune\n'
                      'C.Sambhajinagar (Aurangabad)\n'
                          'Ahmadnagar\n'
                      'Akola\n'
                      'Amravati\n'
                      'Nagpur\n',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'RAJPUROHIT OTC SERVICE was started by MR. Jogsingh Rajpurohit in the year of 2000 and the legacy is being continued by the future generations i.e by his son MR. Mahendrasingh Rajpurohit.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(thickness: 2, color: Colors.grey[300]),

                // Graph Section Title
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'Orders in Last 7 Days',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Orders per Day Graph
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: MediaQuery.of(context).size.width*0.80,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: buildBarChart(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Paid vs Unpaid Graph Title
                Row(
                  children: [
                    Icon(Icons.compare_arrows, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Paid vs Unpaid (Last 7 Days)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Paid vs Unpaid Graph
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  width: MediaQuery.of(context).size.width*0.80,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: buildPaidUnpaidBarChart(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
        ),
      ),
    );
  }
}


