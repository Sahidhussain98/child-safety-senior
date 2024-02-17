import 'package:child_safety/insideapp/GeoMap.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geofencing Input'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _locationNameController,
              decoration: InputDecoration(labelText: 'Location Name'),
            ),
            TextFormField(
              controller: _latitudeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Latitude'),
            ),
            TextFormField(
              controller: _longitudeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Longitude'),
            ),
            TextFormField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Radius (in meters)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                double latitude = double.tryParse(_latitudeController.text) ?? 0.0;
                double longitude = double.tryParse(_longitudeController.text) ?? 0.0;
                double radius = double.tryParse(_radiusController.text) ?? 200.0;
                String locationName = _locationNameController.text;

                // Get the current user's ID using Firebase Authentication
                String userId = getCurrentUserId();

                // Store geofencing data under the user's document in the 'geofencing' subcollection
                await _storeDataInFirestore(userId, locationName, latitude, longitude, radius);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeoMapPage(
                      destinationLatitude: latitude,
                      destinationLongitude: longitude,
                      destinationName: locationName,
                      destinationRadius: radius,
                    ),
                  ),
                );
              },
              child: Text('Show Map'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _storeDataInFirestore(String userId, String name, double latitude, double longitude, double radius) async {
    try {
      // Reference to the 'geofencing' subcollection under the user's document
      CollectionReference<Map<String, dynamic>> userGeofencingCollection =
      FirebaseFirestore.instance.collection('users').doc(userId).collection('geofencing');

      // Store geofencing data in the 'geofencing' subcollection
      await userGeofencingCollection.add({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });
    } catch (e) {
      print('Error storing data in Firestore: $e');
    }
  }

  // Get the current user's ID using Firebase Authentication
  String getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? ''; // Return an empty string if the user is not authenticated
  }
}
