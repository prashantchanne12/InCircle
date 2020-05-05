import 'package:flutter/material.dart';

header(context, {bool isAppTitle = false, String title = 'InCircle'}) {
  return AppBar(
    automaticallyImplyLeading: false,
    elevation: 1.0,
    centerTitle: true,
    backgroundColor: Colors.black87,
    title: Text(
      isAppTitle ? 'InCircle' : title,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Mont',
        color: Colors.white,
        fontSize: isAppTitle ? 23.0 : 20.0,
        letterSpacing: isAppTitle ? 2.0 : 0.7,
      ),
    ),
  );
}
