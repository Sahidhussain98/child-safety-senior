import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PhonePage extends StatefulWidget {
  @override
  _PhonePageState createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController panicMessageController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;
  late FirebaseFirestore _firestore;
  late CollectionReference _contactsRef;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _contactsRef = _firestore.collection('users').doc(_auth.currentUser!.uid).collection('Contacts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.warning),
            onPressed: () {
              _sendPanicMessageToAllContacts();
            },
          ),
        ],
      ),
      body: _buildContactList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddContactDialog(context);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildContactList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _contactsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Widget> contactWidgets = snapshot.data!.docs.map<Widget>((DocumentSnapshot document) {
          Map<String, dynamic>? contactData = document.data() as Map<String, dynamic>?;

          if (contactData != null) {
            String name = contactData['name'] ?? '';
            String number = contactData['number'] ?? '';

            return ListTile(
              title: Text(name),
              subtitle: Text(number),
            );
          }

          return Container();
        }).toList();

        return ListView(
          children: contactWidgets,
        );
      },
    );
  }

  _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Contact'),
          content: Container(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: numberController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                _saveContact();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveContact() {
    _contactsRef.add({
      'name': nameController.text,
      'number': numberController.text,
    }).then((_) {
      print('Contact saved successfully!');
    }).catchError((error) {
      print('Error saving contact: $error');
    });

    // Clear text fields after saving
    nameController.clear();
    numberController.clear();
  }

  void _sendPanicMessageToAllContacts() {
    // Logic to send a panic message to all contacts
    print('Sending panic message to all contacts');
  }
}
