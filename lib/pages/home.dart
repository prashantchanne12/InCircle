import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ff_navigation_bar/ff_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/activity_feed.dart';
import 'package:in_circle/pages/chat.dart';
import 'package:in_circle/pages/create_account.dart';
import 'package:in_circle/pages/profile.dart';
import 'package:in_circle/pages/timeline.dart';
import 'package:in_circle/pages/upload.dart';
import 'package:in_circle/widgets/progress.dart';

final commentsRef = Firestore.instance.collection('comments');
final postRef = Firestore.instance.collection('posts');
final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection('users');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLogin = false;
  bool isLoading = false;
  var phones = [];
  int selectIndex = 0;
  PageController pageController;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();

    pageController = PageController();

    // Google Sign in Listener
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (error) {
      print('Error in Sigining In..');
    });

    // Re-authenticate user when app is reopened
    googleSignIn.signInSilently(suppressErrors: false).then((value) {
      handleSignIn(value);
    }).catchError((error) {
      print('Error in Signing In : $error');
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isLogin = true;
        isLoading = true;
      });

      configurePushNotifications();
    } else {
      setState(() {
        isLogin = false;
        isLoading = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    _firebaseMessaging.getToken().then((token) {
      print('Firebase Messaging Token $token');
      userRef.document(user.id).updateData({"androidNotificationToken": token});
    }, onError: (error) {
      print("Error Occured while getting token $error");
    });

    _firebaseMessaging.configure(
//        // when app is off
//        onLaunch: (Map<String, dynamic> message) async {},
//
//        // when app is running in the background
//        onResume: (Map<String, dynamic> message) async {},

        // when app is active
        onMessage: (Map<String, dynamic> message) async {
      print("on message $message");
      final String recipientId = message['data']['recipient'];
      final String body = message['notification']['body'];

      if (recipientId == user.id) {
        print("Notification shown!");
        SnackBar snackBar = SnackBar(
          content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      } else {
        print("Notification not shown!");
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  createUserInFirestore() async {
    setState(() {
      isLoading = true;
    });
    // Check if the users exists in database
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await userRef.document(user.id).get();

    if (!documentSnapshot.exists) {
      final UserData userData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccount(
            user: user,
          ),
        ),
      );

      // Let's add user to database
      await userRef.document(user.id).setData({
        'id': user.id,
        'photoUrl': userData.photoUrl,
        'email': user.email,
        'displayName': userData.displayName,
        'bio': '',
        'username': userData.username,
        'timestamp': timestamp,
      });

      await followingRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      documentSnapshot = await userRef.document(user.id).get();
    }
    currentUser = User.fromDocument(documentSnapshot);
//    print(currentUser.displayName);
  }

  login() {
    googleSignIn.signIn();
  }

  logout() async {
    await googleSignIn.signOut();
  }

  buildHomePage() {
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: FFNavigationBar(
        theme: FFNavigationBarTheme(
          barBackgroundColor: Colors.white,
          selectedItemBackgroundColor: kPrimaryColor,
          selectedItemIconColor: Colors.white,
          selectedItemLabelColor: Colors.black,
          selectedItemBorderColor: Colors.white,
        ),
        selectedIndex: selectIndex,
        onSelectTab: (index) {
          setState(() {
            this.selectIndex = index;
          });
          pageController.animateToPage(selectIndex,
              duration: Duration(
                milliseconds: 200,
              ),
              curve: Curves.easeInOut);
        },
        items: [
          FFNavigationBarItem(
            iconData: Icons.home,
            label: 'Feed',
          ),
          FFNavigationBarItem(
            iconData: Icons.message,
            label: 'Chats',
          ),
          FFNavigationBarItem(
            iconData: Icons.add_box,
            label: 'Upload',
          ),
          FFNavigationBarItem(
            iconData: Icons.favorite,
            label: 'Activity',
          ),
          FFNavigationBarItem(
            iconData: Icons.account_circle,
            label: 'Profile',
          ),
        ],
      ),
      body: PageView(
        children: <Widget>[
          Timeline(
            user: currentUser,
          ),
          ChatScreen(),
          UploadPost(
            user: currentUser,
          ),
          ActivityFeed(),
          Profile(
            profileId: currentUser.id,
          ),
        ],
        controller: pageController,
        physics: NeverScrollableScrollPhysics(),
      ),
    );
  }

  //----- Authentication Screen -------
  buildLoginScreen() {
    return isLoading
        ? circularProgress()
        : Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: <Widget>[
                Image.asset(
                  'assets/images/login.jpg',
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(top: 150.0),
                      child: Text(
                        'InCircle',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'mont',
                          fontSize: 50.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 130.0,
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          login();
                        },
                        child: Center(
                          child: Container(
                            width: 260.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/google_signin_button.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return isLogin ? buildHomePage() : buildLoginScreen();
  }
}
