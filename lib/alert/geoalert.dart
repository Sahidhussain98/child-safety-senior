import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class GeoAlertPage extends StatefulWidget {
  const GeoAlertPage({Key? key}) : super(key: key);

  @override
  State<GeoAlertPage> createState() => _GeoAlertPageState();
}

class _GeoAlertPageState extends State<GeoAlertPage> {
  Set<Circle> _geofencingCircles = {};
  List<Map<String, dynamic>> _geofencingData = [];
  List<Map<String, dynamic>> _geofenceEvents = [];

  late User? _user;
  late String? userId; // Declare userId at the class level

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
        userId = user?.uid; // Set the value of userId here
      });

      if (user == null) {
        print('User is not logged in.');
      } else {
        _loadData(userId!);
      }
    });
  }

  Future<void> _loadData(String userId) async {
    await _loadGeofencingData(userId);

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _startRealTimeUpdates(userId);
    } else {
      print('User is not logged in.');
    }
  }

  Future<void> _loadGeofencingData(String userId) async {
    try {
      CollectionReference<Map<String, dynamic>> userGeofencingCollection =
      FirebaseFirestore.instance.collection('users').doc(userId).collection('geofencing');

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await userGeofencingCollection.get();
      _geofencingData = querySnapshot.docs
          .map((DocumentSnapshot document) => document.data() as Map<String, dynamic>)
          .toList();

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

  void _startRealTimeUpdates(String userId) {
    Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .snapshots();

    stream.listen((QuerySnapshot snapshot) {
      snapshot.docChanges.forEach((DocumentChange documentChange) {
        String deviceId = documentChange.doc.id;

        documentChange.doc.reference.collection('location').doc('current').get().then(
              (locationSnapshot) {
            if (locationSnapshot.exists) {
              Map<String, dynamic> locationData = locationSnapshot.data() as Map<String, dynamic>;
              double latitude = locationData['latitude'];
              double longitude = locationData['longitude'];

              _checkGeofenceEvent(deviceId, LatLng(latitude, longitude));
            }
          },
        );
      });
    });
  }


  void _checkGeofenceEvent(String deviceId, LatLng position) {
    bool enteredGeofence = _isPositionInsideGeofence(position);
    bool exitedGeofence = !_isPositionInsideGeofence(position);

    print('Entered Geofence: $enteredGeofence');
    print('Exited Geofence: $exitedGeofence');

    if (enteredGeofence) {
      _addGeofenceEvent(deviceId, 'Entered', _getGeofenceName(position));
    } else if (exitedGeofence) {
      _addGeofenceEvent(deviceId, 'Exited', _getGeofenceName(position));
    }
  }

  bool _isPositionInsideGeofence(LatLng position) {
    for (Map<String, dynamic> data in _geofencingData) {
      LatLng geofenceLocation = LatLng(data['latitude'], data['longitude']);
      double geofenceRadius = data['radius'] ?? 200.0;

      double distance = _calculateDistance(position, geofenceLocation);

      if (distance <= geofenceRadius) {
        return true; // Inside the geofence
      }
    }
    return false; // Outside the geofence
  }

  double _calculateDistance(LatLng position1, LatLng position2) {
    return Geolocator.distanceBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );
  }

  String _getGeofenceName(LatLng position) {
    for (Map<String, dynamic> data in _geofencingData) {
      LatLng geofenceLocation = LatLng(data['latitude'], data['longitude']);
      double geofenceRadius = data['radius'] ?? 200.0;

      double distance = _calculateDistance(position, geofenceLocation);

      if (distance <= geofenceRadius) {
        return data['name'] ?? 'Unknown Geofence';
      }
    }
    return 'Unknown Geofence';
  }

  Future<String> _getDeviceName(String userId, String deviceId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> deviceSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .collection('location')
          .doc('current')
          .get();

      if (deviceSnapshot.exists) {
        return deviceSnapshot.data()?['Device Name'] ?? 'Unknown Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      print('Error fetching device name: $e');
      return 'Unknown Device';
    }
  }

  void _addGeofenceEvent(String deviceId, String eventType, String geofenceName) async {
    String deviceName = await _getDeviceName(userId!, deviceId);

    int existingEventIndex = _geofenceEvents.indexWhere((event) => event['deviceId'] == deviceId);

    if (existingEventIndex != -1) {
      setState(() {
        _geofenceEvents[existingEventIndex]['eventType'] = eventType;
        _geofenceEvents[existingEventIndex]['geofenceName'] = geofenceName;
        _geofenceEvents[existingEventIndex]['deviceName'] = deviceName;
        _geofenceEvents[existingEventIndex]['timestamp'] = Timestamp.now();
      });
    } else {
      setState(() {
        _geofenceEvents.add({
          'deviceId': deviceId,
          'deviceName': deviceName,
          'eventType': eventType,
          'geofenceName': geofenceName,
          'timestamp': Timestamp.now(),
        });
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoAlert Events'),
      ),
      body: ListView.builder(
        itemCount: _geofenceEvents.length,
        itemBuilder: (context, index) {
          final event = _geofenceEvents[index];
          return Card(
            elevation: 5.0,
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(
                'Device ID: ${event['deviceId']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device Name: ${event['deviceName']}'),
                  Text('Event Type: ${event['eventType']}'),
                  Text('Geofence Name: ${event['geofenceName']}'),
                  Text('Timestamp: ${_formatTimestamp(event['timestamp'])}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
