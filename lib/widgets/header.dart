import 'package:flutter/material.dart';
import 'package:in_circle/constants.dart';

header(context, {bool isAppTitle = false, String title = 'InCircle'}) {
  return AppBar(
    automaticallyImplyLeading: false,
    elevation: 0.0,
    centerTitle: true,
    backgroundColor: kPrimaryColor,
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
