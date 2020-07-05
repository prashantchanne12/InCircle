import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/main.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'home.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  final bool darkThemeEnabled;

  EditProfile({@required this.currentUserId, this.darkThemeEnabled});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  bool _displayValid = true;
  bool _bioValid = true;

  File file;
  String imageUrlId = Uuid().v4();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w900,
            fontFamily: 'mont',
            color: kPrimaryColor,
          ),
        ),
        leading: (IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: kPrimaryColor,
          ),
        )),
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
          getUserProfile(),
        ],
      ),
    );
  }

  getUserProfile() {
    return StreamBuilder(
      stream: userRef.document(currentUser.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User _user = User.fromDocument(snapshot.data);
        displayNameController.text = _user.displayName;
        bioController.text = _user.bio;
        return ListView(
          shrinkWrap: true,
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      selectImage(context);
                    },
                    child: file != null
                        ? CircleAvatar(
                            child: Icon(
                              Icons.camera_alt,
                              color: kPrimaryColor,
                            ),
                            radius: 60.0,
                            backgroundImage: FileImage(file),
                          )
                        : CircleAvatar(
                            child: Icon(
                              Icons.camera_alt,
                              color: kPrimaryColor,
                            ),
                            radius: 60.0,
                            backgroundColor: Colors.grey,
                            backgroundImage:
                                CachedNetworkImageProvider(_user.photoUrl),
                          ),
                  ),
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
                  Divider(
                    height: 1.0,
                    color: Colors.blueGrey,
                  ),
                  buildDarkThemeButton(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool isSwitched = false;

  buildDarkThemeButton() {
    return ListTile(
      title: Text(
        'Dark Theme',
        style: TextStyle(fontFamily: 'mont'),
      ),
      trailing: Switch(
        value: widget.darkThemeEnabled,
        onChanged: bloc.changeTheme,
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

        userRef.document(widget.currentUserId).updateData({
          'displayName': displayNameController.text,
          'bio': bioController.text,
          'photoUrl': downloadUrl,
        });
      } else {
        userRef.document(widget.currentUserId).updateData({
          'displayName': displayNameController.text,
          'bio': bioController.text,
        });
      }

      setState(() {
        isLoading = false;
        file = null;
      });

      SnackBar snackBar = SnackBar(
        backgroundColor: Colors.green,
        content: Text('Profile Upadted'),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  logout() async {
    makeUserOffline();
    await auth.signOut();
    googleSignIn.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Home()));
  }
}
