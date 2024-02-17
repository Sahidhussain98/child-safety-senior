import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> userData;
  bool isEditMode = false;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController ageController;
  late TextEditingController _contactController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _postofficeController;
  late TextEditingController _policestationController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;

  // Add controllers for other fields

  @override
  void initState() {
    super.initState();
    // Fetch user data when the widget is initialized
    userData = getUserData();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        // Fetch the document ID dynamically based on the user ID
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('user_data')
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Return the first document found (you may need to handle multiple documents differently)
          String documentId = querySnapshot.docs.first.id;
          return await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('user_data')
              .doc(documentId)
              .get();
        } else {
          // Handle the case where no documents are found
          print('No documents found for user ID: $userId');
          throw Exception('No documents found for user ID: $userId');
        }
      } else {
        // Handle the case where no user is logged in
        print('No user is logged in');
        throw Exception('No user is logged in');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw e; // Rethrow the exception to propagate the error
    }
  }

  @override
  void dispose() {
    // Dispose of controllers when the widget is disposed
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    _contactController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postofficeController.dispose();
    _policestationController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    // Dispose other controllers if added

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.save : Icons.edit),
            onPressed: () async {
              if (isEditMode) {
                // Save changes logic here
                await saveChanges();
              }

              // Toggle edit mode
              setState(() {
                isEditMode = !isEditMode;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: userData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('User data not found'));
            }

            // Access the user data
            Map<String, dynamic> userData = snapshot.data!.data()!;

            // Initialize controllers with current data
            firstNameController = TextEditingController(text: userData['first name']);
            lastNameController = TextEditingController(text: userData['last name']);
            ageController = TextEditingController(text: userData['age'].toString());
            _contactController = TextEditingController(text: userData['contact'].toString());
            _address1Controller = TextEditingController(text: userData['address line 1'] ?? '');
            _address2Controller = TextEditingController(text: userData['address line 2'] ?? '');
            _postofficeController = TextEditingController(text: userData['post office'] ?? '');
            _policestationController = TextEditingController(text: userData['police station'] ?? '');
            _districtController = TextEditingController(text: userData['district'] ?? '');
            _stateController = TextEditingController(text: userData['state'] ?? '');
            // Initialize other controllers if added

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildField('First Name', firstNameController),
                  buildField('Last Name', lastNameController),
                  buildField('Age', ageController),
                  buildField('Contact', _contactController),
                  buildField('Address Line 1', _address1Controller),
                  buildField('Address Line 2', _address2Controller),
                  buildField('Post Office', _postofficeController),
                  buildField('Police Station', _policestationController),
                  buildField('District', _districtController),
                  buildField('State', _stateController),

                  // Add other fields as needed
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            isEditMode
                ? TextFormField(
              controller: controller,
              // Add other properties as needed
            )
                : Text(controller.text),
          ],
        ),
      ),
    );
  }

  Future<void> saveChanges() async {
    try {
      // Prompt user for password
      String? enteredPassword = await _showPasswordDialog();

      if (enteredPassword != null) {
        bool isPasswordValid = await validatePassword(enteredPassword);

        if (isPasswordValid) {
          // Password is valid, proceed with saving changes

          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String userId = user.uid;
            String documentId = await getDocumentId(userId);

            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('user_data')
                .doc(documentId)
                .update({
              'first name': firstNameController.text,
              'last name': lastNameController.text,
              'age': int.tryParse(ageController.text) ?? 0,
              'contact': int.tryParse(_contactController.text) ?? 0,
              'address line 1': _address1Controller.text,
              'address line 2': _address2Controller.text,
              'post office': _postofficeController.text,
              'police station': _policestationController.text,
              'district': _districtController.text,
              'state': _stateController.text,
              // Update other fields as needed
            });

            print('Changes saved successfully');

            // Refresh userData to trigger a rebuild of the FutureBuilder
            setState(() {
              userData = getUserData();
            });
          } else {
            print('No user is logged in');
          }
        } else {
          print('Password confirmation failed');
          // Handle incorrect password
        }
      } else {
        // User canceled password input
        print('Password input canceled');
      }
    } catch (e) {
      print('Error saving changes: $e');
    }
  }
  Future<bool> validatePassword(String enteredPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Validate the entered password against the user's actual password
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: enteredPassword);
        await user.reauthenticateWithCredential(credential);
        return true;
      } else {
        print('No user is logged in');
        return false;
      }
    } catch (e) {
      print('Error validating password: $e');
      return false;
    }
  }

  Future<String?> _showPasswordDialog() async {
    TextEditingController passwordController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Your Password'),
          content: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  Future<String> getDocumentId(String userId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_data')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    } else {
      throw Exception('No documents found for user ID: $userId');
    }
  }
}
