import 'package:flutter/material.dart';
import 'package:in_circle/pages/home.dart';

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  logout() async {
    await googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      child: RaisedButton(
        child: Text('Log out'),
        onPressed: () {
          logout();
        },
      ),
    ));
  }
}
