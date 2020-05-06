import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_circle/constants.dart';
import 'package:in_circle/model/user.dart';
import 'package:in_circle/pages/home.dart';
import 'package:in_circle/widgets/post.dart';
import 'package:in_circle/widgets/post_tile.dart';
import 'package:in_circle/widgets/progress.dart';
import 'package:in_circle/pages/edit_profile.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({@required this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  bool isLoading = false;
  String postOrientation = "grid";
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  getFollowers() async {
    QuerySnapshot querySnapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = querySnapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot querySnapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
//      print('Following Count: $followingCount');
      followingCount = querySnapshot.documents.length;
    });
  }

  checkIfFollowing() async {
    DocumentSnapshot documentSnapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();

    setState(() {
      isFollowing = documentSnapshot.exists;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot querySnapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = querySnapshot.documents.length;

      // posts - list containing objects of Post class
      posts = querySnapshot.documents
          .map((DocumentSnapshot documentSnapshot) =>
              Post.fromDocument(documentSnapshot))
          .toList();
//      print(posts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          buildCounts(),
          buildProfilePosts(),
        ],
      ),
    );
  }

  buildProfileHeader() {
    return StreamBuilder(
      stream: userRef.document(widget.profileId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        } else {
          User user = User.fromDocument(snapshot.data);

          return Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 25.0),
            child: Row(
              children: <Widget>[
                Container(
                  child: CircleAvatar(
                    radius: 45.0,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 40.0),
                      alignment: Alignment.center,
                      child: Text(
                        user.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'mont',
                            fontSize: 20.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 40.0, top: 3.0),
                      alignment: Alignment.center,
                      child: Text(
                        user.username,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'mont',
                            fontSize: 18.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    buildProfileButton(),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  buildProfileButton() {
    bool isProfileOwner = widget.profileId == currentUser.id;
    if (isProfileOwner) {
      return buildButton(text: 'Edit Profile', function: handleEditProfile);
    } else if (isFollowing) {
      return buildButton(text: 'Unfollow', function: handleUnFollowUsers);
    } else if (!isFollowing) {
      return buildButton(text: 'Follow', function: handleFollowUsers);
    }
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 10.0, left: 20.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 160.0,
          height: 40.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontFamily: 'mont',
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : kPrimaryColor,
            border: Border.all(
              color: isFollowing ? Colors.grey : kPrimaryColor,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          alignment: Alignment.center,
        ),
      ),
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        padding: EdgeInsets.only(top: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/notPost.svg',
              height: 260.0,
            ),
            Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Text(
                'No Post',
                style: TextStyle(
                    color: kPrimaryColor,
                    fontFamily: 'Mont',
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == 'list') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else {
      return Column(
        children: posts,
      );
    }
  }

  String currentUserId = currentUser?.id;

  handleFollowUsers() {
    setState(() {
      isFollowing = true;
    });

    // Add user to that user's follower collection
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});

    // Update user's following collection
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});

    // add activity feed item for that user to notify about new follower
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImage': currentUser.photoUrl,
      'timestamp': timestamp,
    });
  }

  handleUnFollowUsers() {
    setState(() {
      isFollowing = false;
    });

    // remove user from that user's follower collection
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // remove user from following collection
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete activity feed item for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildCounts() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        buildCountColumns('posts', postCount),
        buildCountColumns('followers', followerCount),
        buildCountColumns('following', followingCount),
      ],
    );
  }

  buildCountColumns(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'mont',
          ),
        ),
        Container(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
              fontFamily: 'mont',
            ),
          ),
        ),
      ],
    );
  }

  handleEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfile()),
    );
  }
}
