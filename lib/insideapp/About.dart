import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About ChildSafety'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ChildSafety App',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'ChildSafety is a mobile app designed to enhance the safety of children. It consists of two components: the Parent App and the Child App.',
              style: TextStyle(fontSize: 18.0, color: Colors.black54),
            ),
            SizedBox(height: 20.0),
            Text(
              'Parent App:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'The Parent App allows parents to monitor the location of their child, set up geofences, and manage emergency contacts.',
              style: TextStyle(fontSize: 18.0, color: Colors.black54),
            ),
            SizedBox(height: 20.0),
            Text(
              'Child App:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'The Child App collects the device location using a unique device ID and sends it to the Parent App. It operates in the background to provide real-time location updates.',
              style: TextStyle(fontSize: 18.0, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
