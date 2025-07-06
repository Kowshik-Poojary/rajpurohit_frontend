import 'package:flutter/material.dart';
import 'package:rajpurohit/origin_destination.dart';
import 'sidebar.dart';
import 'change_address.dart';
import 'sender.dart';
import 'package:rajpurohit/widgets/watermarked_scaffold.dart';

class settings extends StatefulWidget {
  const settings({super.key});

  @override
  State<settings> createState() => _settingsState();
}

class _settingsState extends State<settings> {
  @override
  Widget build(BuildContext context) {
    return WatermarkedScaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff2a3368),
          title: Text('Settings', style: TextStyle(color: Colors.white),),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),

        ),
        drawer: sidebar(),
        body: Column(
          children: [
            ListTile(
              leading: Icon(Icons.home_filled),
              title: Text('Invoice Address'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>address()));
              },
            ),
            ListTile(
              leading: Icon(Icons.trip_origin_outlined),
              title: Text('Origin & Destination'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>origin_destination()));
              },
            ),
            ListTile(
              leading: Icon(Icons.send),
              title: Text('Sender Data'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>sender()));
              },
            ),
          ],
        ),
    );
  }
}
