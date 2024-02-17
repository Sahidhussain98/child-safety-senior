import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeoMapPage extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final double destinationRadius;
  final String destinationName;

  GeoMapPage({
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationRadius,
    required this.destinationName,
  });

  @override
  _GeoMapPageState createState() => _GeoMapPageState();
}

class _GeoMapPageState extends State<GeoMapPage> {
  late GoogleMapController mapController;
  LatLng destinationLocation = LatLng(0, 0);
  Set<Circle> geofencingCircles = {};
  List<Map<String, dynamic>> geofencingData = [];

  @override
  void initState() {
    super.initState();
    destinationLocation = LatLng(widget.destinationLatitude, widget.destinationLongitude);
    _loadGeofencingData();
  }

  Future<void> _loadGeofencingData() async {
    try {
      // Get the current user from Firebase Authentication
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Reference to the 'geofencing' subcollection under the user's document
        CollectionReference<Map<String, dynamic>> userGeofencingCollection =
        FirebaseFirestore.instance.collection('users').doc(user.uid).collection('geofencing');

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await userGeofencingCollection.get();
        geofencingData = querySnapshot.docs.map((DocumentSnapshot document) => document.data() as Map<String, dynamic>).toList();

        setState(() {
          geofencingCircles = _buildGeofencingCircles();
        });
      } else {
        print('User is not logged in.');
      }
    } catch (e) {
      print('Error loading geofencing data from Firestore: $e');
    }
  }
  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: MarkerId('destinationLocation'),
        position: destinationLocation,
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
    );

    for (Map<String, dynamic> data in geofencingData) {
      LatLng geofenceLocation = LatLng(data['latitude'], data['longitude']);

      markers.add(
        Marker(
          markerId: MarkerId(data['name']),
          position: geofenceLocation,
          infoWindow: InfoWindow(title: data['name']),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildGeofencingCircles() {
    Set<Circle> circles = {};

    for (Map<String, dynamic> data in geofencingData) {
      LatLng geofenceLocation = LatLng(data['latitude'], data['longitude']);

      circles.add(
        Circle(
          circleId: CircleId(data['name']),
          center: geofenceLocation,
          radius: data['radius'] ?? 200.0,
          strokeWidth: 2,
          strokeColor: Colors.green,
          fillColor: Colors.green.withOpacity(0.2),
        ),
      );
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map with Geofencing'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: destinationLocation,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: _buildMarkers(),
        circles: geofencingCircles,
      ),
    );
  }
}
