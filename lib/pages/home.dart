import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/activity_feed.dart';
import 'package:in_circle/pages/create_account.dart';
import 'package:in_circle/pages/profile.dart';
import 'package:in_circle/pages/timeline.dart';
import 'package:in_circle/pages/upload.dart';
import 'package:in_circle/widgets/chat_tiles.dart';
import 'package:in_circle/widgets/progress.dart';

final commentsRef = Firestore.instance.collection('comments');
final postRef = Firestore.instance.collection('posts');

FirebaseUser user;
final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection('users');
final FirebaseAuth auth = FirebaseAuth.instance;

final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final chatTilesRef = Firestore.instance.collection('chat_tiles');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
DateTime timestamp = DateTime.now();
User currentUser;
UserData userData;
DocumentSnapshot documentSnapshot;

class Home extends StatefulWidget {
  final bool darkThemeEnabled;

  Home({this.darkThemeEnabled = true});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLogin = false;
  bool isLoading = false;
  int selectIndex = 0;
  PageController pageController;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();

    auth.currentUser().then((user) {
      if (user != null) {
        print(user.uid);
        userRef.document(user.uid).get().then((doc) {
          documentSnapshot = doc;
          currentUser = User.fromDocument(documentSnapshot);
          makeUserOnline();
          setState(() {
            isLogin = true;
          });
        });
      }
    });

    pageController = PageController();
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
    makeUserOffline();
    pageController.dispose();
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    final AuthResult authResult = await auth.signInWithCredential(credential);
    user = authResult.user;
    print('User created : ${user.displayName}');

    final FirebaseUser firebaseUser = await auth.currentUser();

    userRef.document(firebaseUser.uid).get().then((document) {
      if (document.exists) {
        setState(() {
          documentSnapshot = document;
          currentUser = User.fromDocument(documentSnapshot);
          makeUserOnline();
          isLogin = true;
        });
      } else {
        gotoSetupProfile();
      }
    });
  }

  gotoSetupProfile() async {
    if (userData == null) {
      userData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccount(
            user: user,
          ),
        ),
      );

//         Let's add user to database
      userRef.document(user.uid).setData({
        'id': user.uid,
        'photoUrl': userData.photoUrl,
        'email': user.email,
        'displayName': userData.displayName,
        'bio': '',
        'username': userData.username,
        'timestamp': timestamp,
      });

      setState(() {
        userRef.document(user.uid).get().then((DocumentSnapshot doc) {
          documentSnapshot = doc;
        });
        configurePushNotifications();
        isLogin = true;
      });
    }

    documentSnapshot = await userRef.document(user.uid).get();
    currentUser = User.fromDocument(documentSnapshot);
    makeUserOnline();
  }

  int page = 0;

  login() {
    signInWithGoogle();
  }

  logout() async {
    makeUserOffline();
    await googleSignIn.signOut();
  }

  getIconBadge() {
    return StreamBuilder(
      stream: activityFeedRef
          .document(currentUser.id)
          .collection('feedItems')
          .orderBy('timestamp', descending: true)
          .where('isSeen', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          print('wait!!');
        } else {
          page = snapshots.data.documents.length;
        }

        return Stack(
          children: <Widget>[
            Icon(Icons.favorite),
            Positioned(
              right: 0,
              child: page != 0
                  ? Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Container(),
            )
          ],
        );
      },
    );
  }

  buildHomePage() {
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: selectIndex,
        onTap: onTap,
        activeColor: kPrimaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
          ),
          BottomNavigationBarItem(
            icon: getIconBadge(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
      body: PageView(
        children: <Widget>[
          Timeline(
            user: currentUser,
          ),
          ChatTiles(),
//          ChatScreen(),
          UploadPost(
            user: currentUser,
          ),
          ActivityFeed(),
          Profile(
            profileId: currentUser.id,
            darkThemeEnabled: widget.darkThemeEnabled,
          ),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
    );
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.selectIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(
        milliseconds: 200,
      ),
      curve: Curves.easeInOut,
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

  makeUserOnline() {
    // Firestore
    userRef.document(currentUser.id).updateData({
      'online': true,
      'last_active': 0,
    });

    // Firebase
    firebaseDatabase.reference().child('status').update({
      currentUser.id: 'online',
    });

    firebaseDatabase.reference().child('status').onDisconnect().update({
      currentUser.id: 'offline',
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLogin ? buildHomePage() : buildLoginScreen();
  }
}
//
//checkInternetConnectivity() async {
//  try {
//    final result = await InternetAddress.lookup('google.com');
//    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//      return true;
//    }
//  } on SocketException catch (_) {
//    return false;
//  }
//}

makeUserOffline() {
  // Firestore
  userRef.document(currentUser.id).updateData({
    'last_active': DateTime.now(),
  });

  // Firebase
  firebaseDatabase.reference().child('status').update({
    currentUser.id: "offline",
  });
}
