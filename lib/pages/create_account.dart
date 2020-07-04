import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as im;
import 'package:in_circle/constants.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CreateAccount extends StatefulWidget {
  final FirebaseUser user;

  CreateAccount({@required this.user});

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  File file;
  bool isUpload = false;

  TextEditingController usernameController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();

  String username;
  bool _displayValid = true;
  bool _userValid = true;
  String imageUrlId = Uuid().v4();

  @override
  void initState() {
    super.initState();
    displayNameController.text = widget.user.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      body: ListView(
        children: <Widget>[
          isUpload ? linearProgress() : Text(''),
          Column(
            children: <Widget>[
              buildHeader(),
              buildCircleAvatar(),
              buildUsernameField(),
              buildDisplayNameField(),
              buildSubmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, bottom: 10.0, top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'Set up your',
              style: TextStyle(
                color: kPrimaryColor,
                fontFamily: 'mont',
                fontSize: 32.0,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'Profile',
              style: TextStyle(
                color: kPrimaryColor,
                fontFamily: 'mont',
                fontSize: 32.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildCircleAvatar() {
    return GestureDetector(
      onTap: () {
        selectImage(context);
      },
      child: file != null
          ? CircleAvatar(
              child: Icon(
                Icons.camera_alt,
                color: Colors.black,
              ),
              radius: 60.0,
              backgroundImage: FileImage(file),
            )
          : CircleAvatar(
              child: Icon(
                Icons.camera_alt,
                color: Colors.black,
              ),
              radius: 60.0,
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(widget.user.photoUrl),
            ),
    );
  }

  buildUsernameField() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 35.0, left: 20.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'Create username',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'mont',
                  fontSize: 18.0,
                  color: kPrimaryColor),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Container(
            child: TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                  errorText: _userValid ? null : 'name is too short',
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  labelStyle: TextStyle(fontSize: 15.0, fontFamily: 'mont'),
                  hintText: 'Must be atleast 3 characters'),
            ),
          ),
        ),
      ],
    );
  }

  buildDisplayNameField() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 15.0, left: 20.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'Display Name',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'mont',
                  fontSize: 18.0,
                  color: kPrimaryColor),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Container(
            child: TextFormField(
              controller: displayNameController,
              validator: (val) {
                if (val.trim().length < 3 || val.isEmpty) {
                  return 'Display name is too short';
                } else {
                  return null;
                }
              },
              onSaved: (val) => username = val,
              decoration: InputDecoration(
                  errorText: _displayValid ? null : 'name is too short',
                  border: OutlineInputBorder(),
                  labelText: 'Display Name',
                  labelStyle: TextStyle(fontSize: 15.0, fontFamily: 'mont'),
                  hintText: 'Must be atleast 3 characters'),
            ),
          ),
        ),
      ],
    );
  }

  buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.only(top: 25.0, bottom: 10.0),
      child: Container(
        height: 50.0,
        width: 350.0,
        child: Material(
          borderRadius: BorderRadius.circular(9.0),
          color: kPrimaryColor,
          child: InkWell(
            onTap: () {
              updateProfileData();
            },
            child: Center(
              child: Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'mont',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  updateProfileData() async {
    String downloadUrl = '';
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayValid = false
          : _displayValid = true;

      usernameController.text.trim().length < 3 ||
              usernameController.text.isEmpty
          ? _userValid = false
          : _userValid = true;
    });

    if (_displayValid && _userValid) {
      setState(() {
        isUpload = true;
      });

      if (file != null) {
        await compressImage();
        downloadUrl = await uploadImage(file);
      }

      final UserData userData = UserData(
          username: usernameController.text,
          displayName: displayNameController.text,
          photoUrl: file != null ? downloadUrl : widget.user.photoUrl);

      setState(() {
        isUpload = false;
        file = null;
      });

      SnackBar snackBar = SnackBar(
        content: Text('Welcome ${usernameController.text}'),
        backgroundColor: Colors.green,
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, userData);
      });
    }
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 960,
      maxHeight: 675,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  selectImage(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  'Open a Camera',
                  style: TextStyle(fontFamily: 'mont'),
                ),
                onPressed: () => handleTakePhoto(),
              ),
              SimpleDialogOption(
                child: Text(
                  'Open a Gallery',
                  style: TextStyle(fontFamily: 'mont'),
                ),
                onPressed: () => handleChooseFromGallery(),
              ),
              SimpleDialogOption(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'mont',
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    im.Image imageFile = im.decodeImage(file.readAsBytesSync());

    final compressedImageFile = File('$path/$imageUrlId.jpg')
      ..writeAsBytesSync(
        im.encodeJpg(imageFile, quality: 60),
      );

    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask = storageRef
        .child('profile')
        .child('profile_$imageUrlId.jpg')
        .putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    print(downloadUrl);
    return downloadUrl;
  }
}

class UserData {
  final String photoUrl;
  final String username;
  final String displayName;

  UserData({this.photoUrl, this.username, this.displayName});
}

//-------- GOOGLE SIGN IN -----------

//Future<void> signInWithGoogle() async {
//  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
//  final GoogleSignInAuthentication googleSignInAuthentication =
//  await googleSignInAccount.authentication;
//
//  final AuthCredential credential = GoogleAuthProvider.getCredential(
//      idToken: googleSignInAuthentication.idToken,
//      accessToken: googleSignInAuthentication.accessToken);
//
//  final AuthResult authResult = await auth.signInWithCredential(credential);
//  user = authResult.user;
//
//  assert(!user.isAnonymous);
//  assert(await user.getIdToken() != null);
//
//  final FirebaseUser currentUser = await auth.currentUser();
//  assert(user.uid == currentUser.uid);
//
//  print('User created : ${user.displayName}');
//
//  addUserToFireStore(user);
//}
