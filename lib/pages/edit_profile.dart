import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'home.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({@required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _displayValid = true;
  bool _bioValid = true;

  File file;
  String imageUrlId = Uuid().v4();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    userRef
        .document(widget.currentUserId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      setState(() {
        user = User.fromDocument(documentSnapshot);
        displayNameController.text = user.displayName;
        bioController.text = user.bio;
      });
    });
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot documentSnapshot =
        await userRef.document(widget.currentUserId).get();

    setState(() {
      user = User.fromDocument(documentSnapshot);

      displayNameController.text = user.displayName;
      bioController.text = user.bio;

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w900,
            fontFamily: 'mont',
            color: kPrimaryColor,
          ),
        ),
        actions: <Widget>[
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.only(right: 10.0, top: 15.0),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'mont',
                  color: kPrimaryColor,
                ),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isLoading ? linearProgress() : Text(''),
          Container(
            child: Column(
              children: <Widget>[
                buildCircleAvatar(),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField(),
                    ],
                  ),
                ),
                buildUpdateButton(),
                buildLogoutButton(),
              ],
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
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            ),
    );
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
//    print(downloadUrl);
    return downloadUrl;
  }

  buildUpdateButton() {
    return Padding(
      padding: EdgeInsets.only(top: 25.0, bottom: 10.0),
      child: Container(
        height: 40.0,
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
                'Update Profile',
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

  buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.only(top: 25.0, bottom: 10.0),
      child: Container(
        height: 40.0,
        width: 350.0,
        child: Material(
          borderRadius: BorderRadius.circular(9.0),
          color: Colors.white,
          child: InkWell(
            onTap: () {
              logout();
            },
            child: Center(
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: kPrimaryColor,
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

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'Display Name',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: 'Update Display Name',
            errorText: _displayValid ? null : 'name is too short',
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'Bio',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'bio is too long',
          ),
        ),
      ],
    );
  }

  updateProfileData() async {
    String downloadUrl = '';
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayValid = false
          : _displayValid = true;

      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_displayValid && _bioValid) {
      setState(() {
        isLoading = true;
      });

      if (file != null) {
        await compressImage();
        downloadUrl = await uploadImage(file);
      }

      userRef.document(widget.currentUserId).updateData({
        'displayName': displayNameController.text,
        'bio': bioController.text,
        'photoUrl': file != null ? downloadUrl : currentUser.photoUrl
      });

      setState(() {
        isLoading = false;
        file = null;
      });

      SnackBar snackBar = SnackBar(
        backgroundColor: Colors.green,
        content: Text('Profile Upadted'),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);

      getUser();
    }
  }

  logout() async {
    makeUserOffline();
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }
}
