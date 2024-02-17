import 'package:child_safety/insideapp/login.dart';
import 'package:child_safety/insideapp/registerpage.dart';
import 'package:flutter/cupertino.dart';


class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  bool showLoginPage = true;

  void toggleScreens() {

    setState(() {
      showLoginPage = !showLoginPage;
    });

  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return MyLogin(showRegisterPage: toggleScreens);
    }
    else  {
      return RegisterPage(showLoginPage: toggleScreens);
    }
  }
}

