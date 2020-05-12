import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:in_circle/constants.dart';

circularProgress() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 10.0),
    child: SpinKitWave(
      size: 20.0,
      color: kPrimaryColor,
    ),
  );
}

linearProgress() {
  return Container(
    padding: EdgeInsets.only(bottom: 10.0),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Color(0xff0984e3)),
    ),
  );
}

//child: CircularProgressIndicator(
//      valueColor: AlwaysStoppedAnimation(Color(0xff0984e3)),
//    ),
//  );
