import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const kImage1 =
    "https://images.unsplash.com/photo-1575779861872-64e35bb59d2a?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1868&q=80";

const kImage2 =
    "https://images.unsplash.com/photo-1518050346340-aa2ec3bb424b?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=282&q=80";

const kUser =
    "https://www.pngkey.com/png/detail/114-1149878_setting-user-avatar-in-specific-size-without-breaking.png";
//0e1111

const kPrimaryColor = Color(0xff0984e3);

const kSendButtonTextStyle = TextStyle(
  color: kPrimaryColor,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
  fontFamily: 'mont',
);

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: '▶ Type your message here...',
  hintStyle: TextStyle(
    color: Colors.grey,
    fontFamily: 'mont',
  ),
  border: InputBorder.none,
);

const kMessageContainerDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(color: kPrimaryColor, width: 2.0),
  ),
);

const kTextFieldDecoration = InputDecoration(
  hintText: '',
  hintStyle: TextStyle(
    color: Colors.black45,
    fontFamily: 'mont',
  ),
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryColor, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryColor, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);
