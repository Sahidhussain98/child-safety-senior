import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeoTablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geofencing Table'),
      ),
      body: GeoTable(),
    );
  }
}

class GeoTable extends StatefulWidget {
  @override
  _GeoTableState createState() => _GeoTableState();
}

class _GeoTableState extends State<GeoTable> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _getGeofencingData(),
      builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var geofencingData = snapshot.data?.docs;

        return ListView.builder(
          itemCount: geofencingData?.length ?? 0,
          itemBuilder: (context, index) {
            var data = geofencingData![index].data() as Map<String, dynamic>;

            return InkWell(
              onTap: () async {
                bool dataUpdated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDataPage(
                      documentId: geofencingData[index].id,
                      data: data,
                    ),
                  ),
                );

                if (dataUpdated != null && dataUpdated) {
                  _showSnackbar(context, 'Updated');
                }
              },
              child: Card(
                margin: EdgeInsets.all(8.0),
                elevation: 5.0,
                child: ListTile(
                  title: Text(
                    data['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Latitude: ${data['latitude']}, Longitude: ${data['longitude']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getGeofencingData() {
    // Get the current user's ID using Firebase Authentication
    String userId = getCurrentUserId();

    // Reference to the 'geofencing' subcollection under the user's document
    CollectionReference<Map<String, dynamic>> userGeofencingCollection =
    FirebaseFirestore.instance.collection('users').doc(userId).collection('geofencing');

    // Stream to listen for updates in the 'geofencing' subcollection
    return userGeofencingCollection.snapshots();
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 50.0, vertical: 60.0),
      ),
    );
  }

  // Get the current user's ID using Firebase Authentication
  String getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? ''; // Return an empty string if the user is not authenticated
  }
}

class EditDataPage extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  EditDataPage({required this.documentId, required this.data});

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  late TextEditingController nameController;
  late TextEditingController latitudeController;
  late TextEditingController longitudeController;
  late TextEditingController radiusController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name']);
    latitudeController = TextEditingController(text: widget.data['latitude'].toString());
    longitudeController = TextEditingController(text: widget.data['longitude'].toString());
    radiusController = TextEditingController(text: widget.data['radius'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Location Name'),
            _buildTextField(latitudeController, 'Latitude', TextInputType.number),
            _buildTextField(longitudeController, 'Longitude', TextInputType.number),
            _buildTextField(radiusController, 'Radius (in meters)', TextInputType.number),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _updateData(widget.documentId, nameController.text, double.parse(latitudeController.text),
                    double.parse(longitudeController.text), double.parse(radiusController.text));

                // Signal that data is updated
                Navigator.pop(context, true);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType? inputType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }

  Future<void> _updateData(String documentId, String name, double latitude, double longitude, double radius) async {
    try {
      // Get the current user's ID using Firebase Authentication
      String userId = getCurrentUserId();

      // Reference to the 'geofencing' subcollection under the user's document
      CollectionReference<Map<String, dynamic>> userGeofencingCollection =
      FirebaseFirestore.instance.collection('users').doc(userId).collection('geofencing');

      // Update data in the 'geofencing' subcollection
      await userGeofencingCollection.doc(documentId).update({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      });
    } catch (e) {
      print('Error updating data in Firestore: $e');
    }
  }

  // Get the current user's ID using Firebase Authentication
  String getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? ''; // Return an empty string if the user is not authenticated
  }
}
