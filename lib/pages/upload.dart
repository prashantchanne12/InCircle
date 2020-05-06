import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:in_circle/widgets/custom_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as im;

class UploadPost extends StatefulWidget {
  final User user;

  UploadPost({@required this.user});

  @override
  _UploadPostState createState() => _UploadPostState();
}

class _UploadPostState extends State<UploadPost> {
  File file;
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();

  bool isUploading = false;
  String postId = Uuid().v4();

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }

  buildSplashScreen() {
    return Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/upload.svg',
              height: 260.0,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: FlatButton(
                onPressed: () => selectImage(context),
                child: Container(
                  alignment: Alignment.center,
                  width: 160.0,
                  height: 40.0,
                  child: Text(
                    'Upload Image',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'mont',
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ),
          ],
        ));
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
                  style: TextStyle(
                    fontFamily: 'mont',
                    color: Colors.black,
                    fontSize: 17.0,
                  ),
                ),
                onPressed: () => handleTakePhoto(),
              ),
              SimpleDialogOption(
                child: Text(
                  'Open a Gallery',
                  style: TextStyle(
                    fontFamily: 'mont',
                    color: Colors.black,
                    fontSize: 17.0,
                  ),
                ),
                onPressed: () => handleChooseFromGallery(),
              ),
              SimpleDialogOption(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'mont',
                    color: Colors.black,
                    fontSize: 17.0,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      this.file = file;
    });
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: kPrimaryColor,
          onPressed: clearImage,
        ),
        title: Text(
          'Upload Post',
          style: TextStyle(
            fontFamily: 'mont',
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
              child: Text(
                'Post',
                style: TextStyle(
                    color: kPrimaryColor,
                    fontFamily: 'mont',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: isUploading ? null : () => handleSubmit())
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(''),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: FileImage(file)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.user.photoUrl),
            ),
            title: Container(
              color: Colors.white,
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  fontFamily: 'mont',
                ),
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a Caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.blue,
              size: 35.0,
            ),
            title: Container(
              color: Colors.white,
              width: 250.0,
              child: TextField(
                style: TextStyle(
                  fontFamily: 'mont',
                ),
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Location..',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: () {
                getCurrentLocation();
              },
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Use Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'mont',
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  getCurrentLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];

    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      desc: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    im.Image imageFile = im.decodeImage(file.readAsBytesSync());

    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(
        im.encodeJpg(imageFile, quality: 80),
      );

    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('posts').child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore({String mediaUrl, String location, String desc}) {
    postRef
        .document(widget.user.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerId': widget.user.id,
      'username': widget.user.username,
      'mediaUrl': mediaUrl,
      'location': location,
      'desc': desc,
      'timestamp': timestamp,
      'likes': {},
    });
  }
}
