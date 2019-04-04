import 'dart:async';

import 'package:aperture/network/api.dart';
import 'package:aperture/user_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:aperture/auth/ui/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aperture/globals.dart';

Future<void> main() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('isLoggedIn') != null) {
    Globals()
        .cacheTokens(prefs.getString('access'), prefs.getString('refresh'));

    if (await Api.verifyToken()) {
      runApp(MyApp(isLoggedIn: true));
      return;
    }
  }

  runApp(MyApp(isLoggedIn: false));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({@required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aperture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? UserInfoScreen() : LoginScreen(),
    );
  }
}