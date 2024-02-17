import 'package:child_safety/alert/geoalert.dart';
import 'package:child_safety/insideapp/About.dart';
import 'package:child_safety/insideapp/Contacts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:child_safety/insideapp/Mappage.dart';
import 'package:child_safety/insideapp/Show%20Devices.dart';
import 'package:child_safety/insideapp/geoform.dart';
import 'package:child_safety/insideapp/geotable.dart';
import 'package:child_safety/insideapp/profile.dart';

class MyHome extends StatefulWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = {};
    fetchUserData().then((data) {
      setState(() {
        userData = data;
      });
    });
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('user_data')
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          String documentId = querySnapshot.docs.first.id;
          DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('user_data')
              .doc(documentId)
              .get();

          return documentSnapshot.data() ?? {};
        } else {
          print('No documents found for user ID: $userId');
          throw Exception('No documents found for user ID: $userId');
        }
      } else {
        print('No user is logged in');
        throw Exception('No user is logged in');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto', // Use a custom font if desired
      ),
      home: HomeScreen(userData: userData),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 10,
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${widget.userData['first name']} ${widget.userData['last name']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      MaterialButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        color: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).primaryColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                ),
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardItem('Location', Icons.map, Colors.deepOrange),
                  _buildDashboardItem('Geo Alert', Icons.graphic_eq, Colors.green),
                  _buildDashboardItem('Create Geofence', Icons.person, Colors.purple),
                  _buildDashboardItem('Profile', Icons.chat_bubble, Colors.brown),
                  _buildDashboardItem('Geofences list', Icons.list, Colors.indigo),
                  _buildDashboardItem('Show device', Icons.phone_android, Colors.teal),
                  _buildDashboardItem('About', Icons.info, Colors.blue),
                  _buildDashboardItem('Emergency Contact', Icons.phone, Colors.pinkAccent),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardItem(String title, IconData iconData, Color background) {
    return GestureDetector(
      onTap: () => _navigateToPage(title),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: background,
              radius: 30,
              child: Icon(iconData, color: Colors.white, size: 30),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(String title) {
    switch (title) {
      case 'Location':
        Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage()));
        break;
      case 'Show device':
        Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceLocationsPage()));
        break;
      case 'Geofences list':
        Navigator.push(context, MaterialPageRoute(builder: (context) => GeoTablePage()));
        break;
      case 'Create Geofence':
        Navigator.push(context, MaterialPageRoute(builder: (context) => InputPage()));
        break;
      case 'Profile':
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
      case 'Geo Alert':
        Navigator.push(context, MaterialPageRoute(builder: (context) => GeoAlertPage()));
        break;
      case 'About':
        Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
        break;
      case 'Emergency Contact':
        Navigator.push(context, MaterialPageRoute(builder: (context) => PhonePage()));
        break;
    // Add cases for other options if needed
    }
  }
}
