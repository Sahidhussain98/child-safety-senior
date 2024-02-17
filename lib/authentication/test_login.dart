import 'package:child_safety/authentication/authpage.dart';
import 'package:child_safety/insideapp/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class MyVerifylogin extends StatelessWidget {
  const MyVerifylogin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context,snapshot){
            if (snapshot.hasData)
            {
              return MyHome();
            }
            else
            {
              return AuthPage();
            }
          },
        )
    );
  }
}
