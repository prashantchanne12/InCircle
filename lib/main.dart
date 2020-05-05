import 'package:flutter/material.dart';
import 'package:in_circle/pages/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InCircle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xff0984e3),
      ),
      home: Home(),
    );
  }
}
