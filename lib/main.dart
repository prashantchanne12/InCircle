import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/pages/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: bloc.darkThemeEnabled,
      initialData: false,
      builder: (context, snapshot) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'InCircle',
          theme: snapshot.data
              ? ThemeData(
                  brightness: Brightness.dark,
                  primarySwatch: Colors.blue,
                  primaryColor: kPrimaryColor,
                  accentColor: kPrimaryColor,
                  scaffoldBackgroundColor: Color(0xff121212),
                  fontFamily: 'mont',
                  appBarTheme: AppBarTheme(
                    color: Color(0xff121212),
                  ),
                )
              : ThemeData(
                  primarySwatch: Colors.blue,
                  primaryColor: Color(0xff0984e3),
                  appBarTheme: AppBarTheme(
                    color: Colors.white38,
                  ),
                  fontFamily: 'mont',
                ),
          home: Home(
            darkThemeEnabled: snapshot.data,
          ),
        );
      },
    );
  }
}

class Bloc {
  final _themeController = StreamController<bool>();
  get changeTheme => _themeController.sink.add;
  get darkThemeEnabled => _themeController.stream;
}

final bloc = Bloc();
