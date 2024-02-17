import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeviceLocationsPage extends StatefulWidget {
  @override
  _DeviceLocationsPageState createState() => _DeviceLocationsPageState();
}

class _DeviceLocationsPageState extends State<DeviceLocationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Locations'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collectionGroup('location').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List<QueryDocumentSnapshot> locationDocs = snapshot.data!.docs;

          if (locationDocs.isEmpty) {
            return Center(
              child: Text(
                'No device locations available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: locationDocs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> locationData =
              locationDocs[index].data() as Map<String, dynamic>;
              String deviceId =
                  locationDocs[index].reference.parent!.parent!.id;
              String timestamp = locationData['timestamp'];
              double latitude = locationData['latitude'];
              double longitude = locationData['longitude'];
              String deviceName = locationData['Device Name'] ?? 'Unnamed Device';

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'Device ID: $deviceId',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Name: $deviceName',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Location: ($latitude, $longitude)',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Timestamp: $timestamp',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditDeviceDialog(deviceId, deviceName);
                        },
                        color: Colors.teal,
                      ),
                      SizedBox(width: 8.0),
                      IconButton(
                        icon: Icon(Icons.map),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceMap(
                                markers: {
                                  Marker(
                                    markerId: MarkerId(deviceId),
                                    position: LatLng(latitude, longitude),
                                    infoWindow: InfoWindow(title: 'Device $deviceId'),
                                  ),
                                },
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(latitude, longitude),
                                  zoom: 14.0,
                                ),
                              ),
                            ),
                          );
                        },
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDeviceDialog(String deviceId, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        return EditDeviceNamePage(
          deviceId: deviceId,
          currentName: currentName,
          auth: _auth,
        );
      },
    );
  }
}

class EditDeviceNamePage extends StatefulWidget {
  final String deviceId;
  final String currentName;
  final FirebaseAuth auth;

  EditDeviceNamePage({
    required this.deviceId,
    required this.currentName,
    required this.auth,
  });

  @override
  _EditDeviceNamePageState createState() => _EditDeviceNamePageState();
}

class _EditDeviceNamePageState extends State<EditDeviceNamePage> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Device Name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(nameController, 'Device Name'),
          SizedBox(height: 16.0),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _updateDeviceName(widget.deviceId, nameController.text);
              Navigator.pop(context, true);
            },
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }

  Future<void> _updateDeviceName(String deviceId, String newName) async {
    try {
      // Build the path to the "current" document
      String currentDocumentPath =
          'users/${widget.auth.currentUser!.uid}/devices/$deviceId/location/current';

      await FirebaseFirestore.instance
          .doc(currentDocumentPath)
          .update({'Device Name': newName});
    } catch (e) {
      print('Error updating device name in Firestore: $e');
    }
  }
}

class DeviceMap extends StatefulWidget {
  final Set<Marker> markers;
  final CameraPosition initialCameraPosition;

  DeviceMap({
    required this.markers,
    required this.initialCameraPosition,
  });

  @override
  _DeviceMapState createState() => _DeviceMapState();
}

class _DeviceMapState extends State<DeviceMap> {
  Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: widget.initialCameraPosition,
        markers: widget.markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
