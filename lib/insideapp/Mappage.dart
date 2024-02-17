import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = {};
  Set<Circle> _geofencingCircles = {};
  List<Map<String, dynamic>> _geofencingData = [];

  Set<Marker> _deviceMarkers = {};
  List<String> _deviceIds = [];

  Future<void> handleDisabledLocationServices() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Location Services Disabled"),
            content: Text("Please enable location services in your device settings."),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openLocationSettings();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _loadGeofencingData(String userId) async {
    try {
      CollectionReference<Map<String, dynamic>> userGeofencingCollection =
      FirebaseFirestore.instance.collection('users').doc(userId).collection('geofencing');

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await userGeofencingCollection.get();
      _geofencingData = querySnapshot.docs.map((DocumentSnapshot document) => document.data() as Map<String, dynamic>).toList();

      setState(() {
        _geofencingCircles = _buildGeofencingCircles();
      });
    } catch (e) {
      print('Error loading geofencing data from Firestore: $e');
    }
  }

  Set<Circle> _buildGeofencingCircles() {
    Set<Circle> circles = {};

    for (Map<String, dynamic> data in _geofencingData) {
      LatLng geofenceLocation = LatLng(data['latitude'], data['longitude']);

      circles.add(
        Circle(
          circleId: CircleId(data['name']),
          center: geofenceLocation,
          radius: data['radius'] ?? 200.0,
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.2),
        ),
      );
    }

    return circles;
  }

  Set<Marker> _buildMarkers(Position currentLocation) {
    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: LatLng(currentLocation.latitude, currentLocation.longitude),
        infoWindow: InfoWindow(
          title: 'My current location',
        ),
      ),
    );

    markers.addAll(_deviceMarkers.map((deviceMarker) {
      return Marker(
        markerId: deviceMarker.markerId,
        position: deviceMarker.position,
        infoWindow: deviceMarker.infoWindow,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }));

    markers.addAll(_geofencingData.map((data) {
      LatLng geofenceLocation = LatLng(data['latitude'], data['longitude']);

      return Marker(
        markerId: MarkerId(data['name']),
        position: geofenceLocation,
        infoWindow: InfoWindow(title: data['name']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }));

    return markers;
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission().then((value) {}).onError((error, stackTrace) {
      print("Error: " + error.toString());
    });

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _loadDeviceIds(String userId) async {
    try {
      CollectionReference<Map<String, dynamic>> userDevicesCollection =
      FirebaseFirestore.instance.collection('users').doc(userId).collection('devices');

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await userDevicesCollection.get();
      _deviceIds = querySnapshot.docs.map((DocumentSnapshot document) => document.id).toList();

      await _loadDeviceData(userId);
      setState(() {
        _deviceMarkers = _buildDeviceMarkers();
      });
    } catch (e) {
      print('Error loading device IDs from Firestore: $e');
    }
  }

  Future<void> _loadDeviceData(String userId) async {
    try {
      _deviceMarkers.clear();

      for (String deviceId in _deviceIds) {
        DocumentSnapshot<Map<String, dynamic>> deviceSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(deviceId)
            .collection('location')
            .doc('current')
            .get();

        if (deviceSnapshot.exists) {
          Map<String, dynamic> deviceData = deviceSnapshot.data() ?? {};
          String deviceName = deviceData['Device Name'] ?? 'Unnamed Device';
          LatLng deviceLocation = LatLng(deviceData['latitude'] ?? 0, deviceData['longitude'] ?? 0);

          _deviceMarkers.add(
            Marker(
              markerId: MarkerId(deviceId),
              position: deviceLocation,
              infoWindow: InfoWindow(
                title: deviceName,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading device data from Firestore: $e');
    }
  }

  Set<Marker> _buildDeviceMarkers() {
    Set<Marker> markers = {};

    markers.addAll(_deviceMarkers.map((deviceMarker) {
      return Marker(
        markerId: deviceMarker.markerId,
        position: deviceMarker.position,
        infoWindow: deviceMarker.infoWindow,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
    }));

    return markers;
  }

  void _startRealTimeUpdates(String userId) {
    // Stream that listens to changes in the "location" subcollection
    Stream<QuerySnapshot> stream = FirebaseFirestore.instance.collectionGroup('location').snapshots();

    stream.listen((QuerySnapshot snapshot) {
      // Handle each document in the snapshot to update markers
      snapshot.docChanges.forEach((DocumentChange documentChange) {
        // Extract data from the document
        Map<String, dynamic> locationData = documentChange.doc.data() as Map<String, dynamic>;
        String deviceId = documentChange.doc.reference.parent!.parent!.id;
        double latitude = locationData['latitude'];
        double longitude = locationData['longitude'];

        // Update or add a marker based on the document change type
        if (documentChange.type == DocumentChangeType.modified) {
          // Marker already exists, so update its position
          _updateMarker(deviceId, LatLng(latitude, longitude));
        } else if (documentChange.type == DocumentChangeType.added) {
          // New marker, add it to the set
          _addMarker(deviceId, LatLng(latitude, longitude));
        } else if (documentChange.type == DocumentChangeType.removed) {
          // Marker removed, remove it from the set
          _removeMarker(deviceId);
        }
      });
    });
  }

  void _addMarker(String deviceId, LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(deviceId),
          position: position,
          infoWindow: InfoWindow(title: 'Device $deviceId'),
          icon: _deviceIds.contains(deviceId)
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _updateMarker(String deviceId, LatLng position) {
    // Find and update the existing marker
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == deviceId);
      _markers.add(
        Marker(
          markerId: MarkerId(deviceId),
          position: position,
          infoWindow: InfoWindow(title: 'Device $deviceId'),
          icon: _deviceIds.contains(deviceId)
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  void _removeMarker(String deviceId) {
    // Remove the marker associated with the removed device
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == deviceId);
    });
  }

  loadData() async {
    await handleDisabledLocationServices();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;
      print('User ID: $userId');

      await _loadGeofencingData(userId);
      await _loadDeviceIds(userId);

      getUserCurrentLocation().then((value) async {
        if (value == null) return;

        CameraPosition cameraPosition = CameraPosition(
          zoom: 16,
          target: LatLng(value.latitude, value.longitude),
        );

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        setState(() {
          _markers = _buildMarkers(value);
        });
      });

      // Start real-time updates
      _startRealTimeUpdates(userId);
    } else {
      print('User is not logged in.');
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Page'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 16,
        ),
        mapType: MapType.hybrid,
        markers: _markers,
        circles: _geofencingCircles,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.65,
          right: 35,
          left: 35,
        ),
        child: Row(
          children: [
            FloatingActionButton(
              onPressed: () async {
                getUserCurrentLocation().then((value) async {
                  if (value == null) return;

                  CameraPosition cameraPosition = CameraPosition(
                    zoom: 16,
                    target: LatLng(value.latitude, value.longitude),
                  );

                  final GoogleMapController controller = await _controller.future;
                  controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

                  setState(() {
                    _markers = _buildMarkers(value);
                  });
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
