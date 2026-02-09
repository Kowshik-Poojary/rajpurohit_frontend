import 'package:flutter/material.dart';
import 'package:rajpurohit/add_data.dart';
import 'package:rajpurohit/main.dart';
import 'package:rajpurohit/previous_data.dart';
import 'package:rajpurohit/settings.dart';

import 'Homepage.dart';
class sidebar extends StatefulWidget {
  const sidebar({super.key});

  @override
  State<sidebar> createState() => _sidebarState();
}

class _sidebarState extends State<sidebar> {

  Future<void> showLoginPrompt() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Map<String, String> credentials = {
      'Rajpurohit': '1008',
      'mahendra': '9892',
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Credentials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                final enteredUsername = usernameController.text.trim();
                final enteredPassword = passwordController.text;

                if (credentials.containsKey(enteredUsername) &&
                    credentials[enteredUsername] == enteredPassword) {
                  Navigator.pop(context);

                  // Navigate to your page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => settings()),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid username or password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.all(0),
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xff2a3368),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the logo (adjust the image path and size as needed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipOval(
                      child: Container(
                        color: Colors.white, // Optional background
                        width: 100,  // radius * 2
                        height: 100,
                        child: Image.asset(
                          'assets/images/logo1.png',
                          fit: BoxFit.contain, // Ensures full image is visible
                        ),
                      ),
                    ),
                    GestureDetector(onTap: () {Navigator.pop(context); }, child: Container(child: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white,)))
                  ],
                ),

                SizedBox(height: 10),
                // Company Name or Sidebar Title
                Text(
                  'RAJPUROHIT OTC SERVICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> homepage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.add_chart),
            title: Text('Add New'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> add_data()));
            },
          ),
          ListTile(
            leading: Icon(Icons.preview),
            title: Text('Previous Data'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> previous_data()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              showLoginPrompt();
              },
          ),
        ],
      ),
    );
  }
}
