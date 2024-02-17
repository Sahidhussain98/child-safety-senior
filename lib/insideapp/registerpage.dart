import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;

  const RegisterPage({Key? key, required this.showLoginPage}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Map<String, TextEditingController> _controllers = {
    'first name': TextEditingController(),
    'last name': TextEditingController(),
    'age': TextEditingController(),
    'contact': TextEditingController(),
    'address1': TextEditingController(),
    'address2': TextEditingController(),
    'post office': TextEditingController(),
    'police station': TextEditingController(),
    'district': TextEditingController(),
    'state': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'confirm password': TextEditingController(),
  };

  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> signUp() async {
    if (passwordConfirmed() && _validateEmail() && _validateFields()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _controllers['email']!.text.trim(),
          password: _controllers['password']!.text.trim(),
        );

        await addUserDetails(
          userCredential.user!.uid,
          _controllers['first name']!.text.trim(),
          _controllers['last name']!.text.trim(),
          int.parse(_controllers['age']!.text.trim()),
          int.parse(_controllers['contact']!.text.trim()),
          _controllers['address1']!.text.trim(),
          _controllers['address2']!.text.trim(),
          _controllers['post office']!.text.trim(),
          _controllers['police station']!.text.trim(),
          _controllers['district']!.text.trim(),
          _controllers['state']!.text.trim(),
        );

        print('User registered successfully');
      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException: $e');
      }
    }
  }

  Future<void> addUserDetails(
      String userId,
      String firstname,
      String lastname,
      int age,
      int contact,
      String address1,
      String address2,
      String postoffice,
      String policestation,
      String district,
      String state,
      ) async {
    try {
      CollectionReference<Map<String, dynamic>> userDataCollection =
      FirebaseFirestore.instance.collection('users').doc(userId).collection('user_data');

      Map<String, dynamic> userData = {
        'first name': firstname,
        'last name': lastname,
        'age': age,
        'contact': contact,
        'address line 1': address1,
        'address line 2': address2,
        'post office': postoffice,
        'police station': policestation,
        'district': district,
        'state': state,
      };

      await userDataCollection.add(userData);

      print('User data added successfully');
    } catch (e) {
      print('Error storing user details in Firestore: $e');
    }
  }

  bool passwordConfirmed() {
    return _controllers['password']!.text.trim() == _controllers['confirm password']!.text.trim();
  }

  bool _validateEmail() {
    String email = _controllers['email']!.text.trim();
    bool isValid = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(email);
    if (!isValid) {
      setState(() {
        _errors['email'] = 'Enter a valid email address';
      });
    } else {
      setState(() {
        _errors.remove('email');
      });
    }
    return isValid;
  }

  bool _validateFields() {
    bool isValid = true;
    _controllers.forEach((key, controller) {
      if (controller.text.trim().isEmpty) {
        setState(() {
          _errors[key] = 'Field cannot be empty';
        });
        isValid = false;
      } else {
        setState(() {
          _errors.remove(key);
        });
      }
    });
    return isValid;
  }

  Future<void> _showRegistrationPopup() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: 0,
          right: 0,
          child: AlertDialog(
            title: const Text('User Registration'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  buildTextField('First Name', _controllers['first name']!),
                  const SizedBox(height: 10),
                  buildTextField('Last Name', _controllers['last name']!),
                  const SizedBox(height: 10),
                  buildDoubleTextField('Age', _controllers['age']!, 'Contact Number', _controllers['contact']!),
                  const SizedBox(height: 10),
                  buildTextField('Address Line 1', _controllers['address1']!),
                  const SizedBox(height: 10),
                  buildTextField('Address Line 2', _controllers['address2']!),
                  const SizedBox(height: 10),
                  buildDoubleTextField('Local Post Office', _controllers['post office']!, 'Local Police Station', _controllers['police station']!),
                  const SizedBox(height: 10),
                  buildDoubleTextField('District', _controllers['district']!, 'State', _controllers['state']!),
                  const SizedBox(height: 10),
                  buildTextField('Email', _controllers['email']!),
                  if (_errors.containsKey('email'))
                    Text(
                      _errors['email']!,
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  buildTextField('Password', _controllers['password']!, obscureText: true),
                  const SizedBox(height: 10),
                  buildTextField('Confirm Password', _controllers['confirm password']!, obscureText: true),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  signUp(); // Call signUp when "Sign Up" button is pressed
                  Navigator.of(context).pop();
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTextField(String hint, TextEditingController controller, {bool obscureText = false}) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildDoubleTextField(String hint1, TextEditingController controller1, String hint2, TextEditingController controller2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: buildTextField(hint1, controller1)),
        const SizedBox(width: 10),
        Expanded(child: buildTextField(hint2, controller2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.5),
                Text(
                  'Hello There!',
                  style: GoogleFonts.sacramento(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 50,
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _showRegistrationPopup, // Call the new function here
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already a member?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: widget.showLoginPage,
                  child: const Text(
                    ' Login',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
