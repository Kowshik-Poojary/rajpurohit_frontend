import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rajpurohit/login.dart';
import 'config/api.dart';
import 'sidebar.dart';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

class OrderStats {
  final String date;
  final int orders;

  OrderStats({required this.date, required this.orders});

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      date: json['day']?.toString() ?? '',
      orders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
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
      date: json['day']?.toString() ?? '',
      paid: int.tryParse(json['paid']?.toString() ?? '0') ?? 0,
      unpaid: int.tryParse(json['unpaid']?.toString() ?? '0') ?? 0,
    );
  }
}

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> with TickerProviderStateMixin {
  List<OrderStats> weeklyStats = [];
  List<PaidUnpaidStats> paidUnpaidList = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    setupAnimations();
    fetchWeeklyOrders();
    fetchPaidUnpaidStats();
  }

  void setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> fetchPaidUnpaidStats() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/paid-unpaid-stats'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          paidUnpaidList = data.map((e) => PaidUnpaidStats.fromJson(e)).toList();
        });
      } else {
        print('❌ Failed to fetch paid/unpaid stats');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchWeeklyOrders() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/orders-per-day'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          weeklyStats = data.map((e) => OrderStats.fromJson(e)).toList();
        });
      } else {
        print('❌ Failed to fetch order stats');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget buildPaidUnpaidBarChart() {
    if (paidUnpaidList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('Loading data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade200,
            tooltipBorder: BorderSide(color: Colors.grey.shade400),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Paid' : 'Unpaid';
              return BarTooltipItem(
                '$label: ${rod.toY.toInt()}',
                TextStyle(
                  color: rodIndex == 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= paidUnpaidList.length) return SizedBox();
                String rawDate = paidUnpaidList[index].date;

                if (rawDate.isEmpty) return SizedBox();

                DateTime? date;
                try {
                  date = DateTime.parse(rawDate);
                } catch (_) {
                  return Text(rawDate, style: TextStyle(fontSize: 9));
                }

                return Text("${date.day}/${date.month}", style: TextStyle(fontSize: 9, color: Colors.grey));
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
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: stat.paid.toDouble(),
                color: Colors.green.shade400,
                width: 10,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: stat.unpaid.toDouble(),
                color: Colors.red.shade400,
                width: 10,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }).toList(),
        maxY: paidUnpaidList
            .map((e) => (e.paid > e.unpaid ? e.paid : e.unpaid))
            .reduce((a, b) => a > b ? a : b)
            .toDouble() +
            5,
      ),
    );
  }

  Widget buildBarChart() {
    if (weeklyStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('Loading data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.deepPurple.shade100,
              tooltipBorder: BorderSide(color: Colors.purple.shade900, width: 1),
              tooltipPadding: EdgeInsets.all(8),
              tooltipMargin: 12,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} Orders',
                  TextStyle(
                    color: Colors.purple.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          alignment: BarChartAlignment.spaceAround,
          maxY: weeklyStats.map((e) => e.orders).reduce((a, b) => a > b ? a : b).toDouble() + 5,
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
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= weeklyStats.length) return SizedBox();
                  String rawDate = weeklyStats[index].date;

                  if (rawDate.isEmpty) return SizedBox();

                  DateTime? date;
                  try {
                    date = DateTime.parse(rawDate);
                  } catch (_) {
                    return Text(rawDate, style: TextStyle(fontSize: 9));
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("${date.day}/${date.month}", style: TextStyle(fontSize: 9, color: Colors.grey)),
                  );
                },
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
        backgroundColor: const Color(0xff2a3368),
        title: const Text(
          'HOME',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: sidebar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xff2a3368).withOpacity(0.05),
              Colors.blue.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Welcome Text with Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xff2a3368), const Color(0xff3d4a8a)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff2a3368).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.waving_hand, color: Colors.amber, size: 28),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome to RAJPUROHIT OTC SERVICE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section 1
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.local_shipping, color: Colors.blue, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'About Us',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'RAJPUROHIT OTC SERVICE is dedicated to providing reliable courier and logistics solutions across India. With our commitment to speed, safety, and customer satisfaction, we aim to simplify every delivery experience.\n\n'
                                  'Daily seamless Courier services within destinations:\n'
                                  '• Mumbai\n'
                                  '• Pune\n'
                                  '• C.Sambhajinagar (Aurangabad)\n'
                                  '• Ahmadnagar\n'
                                  '• Akola\n'
                                  '• Amravati\n'
                                  '• Nagpur',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section 2
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.history, color: Colors.amber, size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Our Legacy',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'RAJPUROHIT OTC SERVICE was started by MR. Jogsingh Rajpurohit in the year 2000 and the legacy is being continued by the future generations i.e., by his son MR. Mahendrasingh Rajpurohit.\n\n'
                                  'Over two decades of trusted service and continuous innovation in logistics.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Divider(thickness: 2, color: Colors.grey.shade200),

                  const SizedBox(height: 24),

                  // Orders Chart Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bar_chart, color: Colors.purple, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Orders in Last 7 Days',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Orders Chart
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.50,
                          width: double.infinity,
                          child: buildBarChart(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Paid vs Unpaid Chart Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.compare_arrows, color: Colors.teal, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Paid vs Unpaid (Last 7 Days)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Paid vs Unpaid Chart
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.50,
                          width: double.infinity,
                          child: buildPaidUnpaidBarChart(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}