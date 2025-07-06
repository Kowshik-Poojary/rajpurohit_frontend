// widgets/watermarked_scaffold.dart
import 'package:flutter/material.dart';

class WatermarkedScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final FloatingActionButton? floatingActionButton;

  const WatermarkedScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // ✅ Watermark
          Align(
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.1,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ✅ Main content
          body,
        ],
      ),
    );
  }
}
